# Interim formula: installs prebuilt binaries from roc-lang/nightlies until Roc has
# a stable release that can go to homebrew-core. Kept in sync with the release in
# roc-lang.org's install_roc.sh by .github/workflows/update.yml.
class Roc < Formula
  desc "Fast, friendly, functional programming language"
  homepage "https://www.roc-lang.org"
  version "2026-11-15-f25da45"
  license "UPL-1.0"

  uses_from_macos "expect" => :test

  on_macos do
    # macOS 15 is the oldest version Roc is tested on.
    depends_on macos: :sequoia

    on_arm do
      url "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-11-15-f25da45/roc_nightly-macos_apple_silicon-2026-11-15-f25da45.tar.gz"
      sha256 "3bbdc4d4c70c3446f6e59504c7f0e122cae1de27d6f94be74c41ed7218fe0896"
    end
    on_intel do
      url "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-11-15-f25da45/roc_nightly-macos_x86_64-2026-11-15-f25da45.tar.gz"
      sha256 "804510f5fd252261c2163d2e6105c69a19208075d35926ee22b59e04f9c00afb"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-11-15-f25da45/roc_nightly-linux_arm64-2026-11-15-f25da45.tar.gz"
      sha256 "dfc97c6ddf897d7717cb95a19e0c0a98d1d4afae4f259e691f8959870f379176"
    end
    on_intel do
      url "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-11-15-f25da45/roc_nightly-linux_x86_64-2026-11-15-f25da45.tar.gz"
      sha256 "986360348a6bbf4f27696f6b3d73f0260293813346712a3f72e736452671e994"
    end
  end

  # The examples revision that roc-lang.org's examples.json pins; `brew test` runs its CI script
  # on the examples that pin this formula's Roc version.
  resource "examples" do
    url "https://github.com/roc-lang/examples/archive/70df898338b5499be1165c971711f1fc1d05225d.tar.gz"
    sha256 "7bfdbbdf9070451be551c9fc2b8c99d32fccca96e1d64db7f70747edc8a735ad"
  end

  def install
    # roc links against the `darwin` sysroot next to its symlink-resolved path, so keep them together.
    libexec.install "roc"
    libexec.install "darwin" if OS.mac?
    bin.install_symlink libexec/"roc"
    prefix.install "legal_details"
  end

  test do
    assert_equal "Roc compiler version nightly-#{version}", shell_output("#{bin}/roc version").strip

    resource("examples").stage testpath
    # Each example pins its Roc nightly in its header; only those pinning this release must pass with it.
    pin = "roc: \"nightly-#{version}\""
    examples = (testpath/"examples").children.select do |dir|
      dir.glob("**/*.roc").any? { |file| file.read.include?(pin) }
    end
    refute_empty examples, "no example pins nightly-#{version}"
    ENV["ROC"] = bin/"roc"
    system "bash", "ci_scripts/all_tests.sh", *examples.map { |dir| dir.basename.to_s }
  end
end
