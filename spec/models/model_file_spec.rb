require "rails_helper"
require "support/mock_directory"

RSpec.describe ModelFile do
  it_behaves_like "Listable"

  it "is not valid without a filename" do
    expect(build(:model_file, filename: nil)).not_to be_valid
  end

  it "is not valid without being part of a model" do
    expect(build(:model_file, model: nil)).not_to be_valid
  end

  it "is valid if it has a filename and model" do
    expect(build(:model_file)).to be_valid
  end

  it "must have a unique filename within its model" do
    model = create(:model, path: "model")
    create(:model_file, model: model, filename: "part.stl")
    expect(build(:model_file, model: model, filename: "part.stl")).not_to be_valid
  end

  it "can have the same filename as a file in a different model" do
    library = create(:library)
    model1 = create(:model, library: library, path: "model1")
    create(:model_file, model: model1, filename: "part.stl")
    model2 = create(:model, library: library, path: "model2")
    expect(build(:model_file, model: model2, filename: "part.stl")).to be_valid
  end

  it "calculates a bounding box for model" do
    library = create(:library, path: Rails.root.join("spec/fixtures"))
    model1 = create(:model, library: library, path: "model_file_spec")
    part = create(:model_file, model: model1, filename: "example.obj", attachment: nil)
    expect(part.bounding_box).to eq([10, 15, 20])
  end

  it "calculates file size when attached" do
    library = create(:library, path: Rails.root.join("spec/fixtures"))
    model1 = create(:model, library: library, path: "model_file_spec")
    part = create(:model_file, model: model1, filename: "example.obj", attachment: nil)
    expect(part.size).to eq(284)
  end

  it "calculates digest for a file" do
    library = create(:library, path: Rails.root.join("spec/fixtures"))
    model1 = create(:model, library: library, path: "model_file_spec")
    part = create(:model_file, model: model1, filename: "example.obj", attachment: nil)
    expect(part.calculate_digest.first(16)).to eq("8a0f188378204b67")
  end

  it "finds duplicate files using digest" do # rubocop:todo RSpec/ExampleLength, RSpec/MultipleExpectations
    library = create(:library, path: Rails.root.join("/tmp"))
    model = create(:model, library: library, path: "model")
    part1 = create(:model_file, model: model, filename: "same.obj", digest: "1234")
    part2 = create(:model_file, model: model, filename: "same.stl", digest: "1234")
    create(:model_file, model: model, filename: "different.stl", digest: "4321")
    allow(part1).to receive(:size).and_return(123)
    expect(part1.duplicate?).to be true
    expect(part1.duplicates).to eq [part2]
  end

  it "does not flag duplicates for nil digests" do # rubocop:todo RSpec/ExampleLength
    library = create(:library, path: Rails.root.join("/tmp"))
    model = create(:model, library: library, path: "model1")
    part1 = create(:model_file, model: model, filename: "nil.obj", digest: nil)
    create(:model_file, model: model, filename: "nil.stl", digest: nil)
    expect(part1.duplicate?).to be false
  end

  it "does not flag duplicates for zero-length files" do # rubocop:todo RSpec/ExampleLength
    library = create(:library, path: Rails.root.join("/tmp"))
    model = create(:model, library: library, path: "model1")
    part1 = create(:model_file, model: model, filename: "same.obj", digest: "1234")
    create(:model_file, model: model, filename: "same.stl", digest: "1234")
    allow(part1).to receive(:size).and_return(0)
    expect(part1.duplicate?).to be false
  end

  context "with actual files on disk" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.3mf"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    let(:library) { create(:library, path: @library_path) } # rubocop:todo RSpec/InstanceVariable
    let(:model) { create(:model, library: library, path: "model_one") }
    let(:file) { create(:model_file, model: model, filename: "part_1.3mf", digest: "1234") }

    it "removes original file from disk" do
      expect { file.destroy }.to(
        change { File.exist?(File.join(library.path, file.path_within_library)) }.from(true).to(false)
      )
    end

    it "does not remove original file from disk when deleted, not destroyed" do
      expect { file.delete }.not_to(
        change { File.exist?(File.join(library.path, file.path_within_library)) }
      )
    end

    it "ignores missing files on deletion" do
      file.update! filename: "gone.3mf"
      expect { file.destroy }.not_to raise_exception
    end

    it "queues up rescans for duplicates on destroy" do
      dupe = create(:model_file, model: model, filename: "duplicate.3mf", digest: "1234")
      expect { file.destroy }.to(
        have_enqueued_job(Analysis::AnalyseModelFileJob).with(dupe.id)
      )
    end
  end

  context "with different versions of the same file" do
    let!(:model) { create(:model) }
    let!(:presupported) { create(:model_file, model: model, presupported: true) }
    let!(:unsupported) { create(:model_file, model: model, presupported: false, presupported_version: presupported) }

    it "can access supported part from unsupported part" do
      expect(unsupported.presupported_version).to eq presupported
    end

    it "can access unsupported part from presupported part" do
      expect(presupported.unsupported_version).to eq unsupported
    end

    it "only let presupported files be set as the presupported_version" do # rubocop:todo RSpec/MultipleExpectations
      another_unsupported = create(:model_file, model: model, presupported: false)
      unsupported.presupported_version = another_unsupported
      expect(unsupported).not_to be_valid
      expect(unsupported.errors[:presupported_version].first).to eq "is not a presupported file"
    end

    it "does not allow a presupported_version to be set for presupported files" do # rubocop:todo RSpec/MultipleExpectations
      another_presupported = create(:model_file, model: model, presupported: true)
      presupported.presupported_version = another_presupported
      expect(presupported).not_to be_valid
      expect(presupported.errors[:presupported_version].first).to eq "cannot be set on a presupported file"
    end

    it "clears presupported version if presupported file is set to unsupported" do
      presupported.update!(presupported: false)
      expect(unsupported.reload.presupported_version).to be_nil
    end
  end

  {
    stl: true,
    png: false,
    pdf: false,
    lys: false
  }.each_pair do |extension, result|
    it "shows that #{extension} files are#{"n't" if result == false} renderable" do
      file = create(:model_file, filename: "test.#{extension}")
      expect(file.is_renderable?).to be result
    end
  end
end
