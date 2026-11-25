# Interim formula: installs prebuilt binaries from roc-lang/roc releases until Roc has
# a stable release that can go to homebrew-core. Kept in sync with the release in
# roc-lang.org's install_roc.sh by .github/workflows/update.yml.
class Roc < Formula
  desc "Fast, friendly, functional programming language"
  homepage "https://www.roc-lang.org"
  license "UPL-1.0"
  # Nightly versions like 2026-11-15-f25da45 would otherwise sort above 0.1.0_RC1.
  version_scheme 1

  uses_from_macos "expect" => :test

  on_macos do
    # macOS 15 is the oldest version Roc is tested on.
    depends_on macos: :sequoia

    on_arm do
      url "https://github.com/roc-lang/roc/releases/download/0.1.0_RC1/roc-macos_apple_silicon-0.1.0_RC1.tar.gz"
      sha256 "e8228040c701e130254c72539a1d0f1b150d78c00058747edb0edae51ba5dbc8"
    end
    on_intel do
      url "https://github.com/roc-lang/roc/releases/download/0.1.0_RC1/roc-macos_x86_64-0.1.0_RC1.tar.gz"
      sha256 "ea9b38b5e4708cbe42c92077e816f5241299da1aa3f4c46e8cb933b1aa2af858"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/roc-lang/roc/releases/download/0.1.0_RC1/roc-linux_arm64-0.1.0_RC1.tar.gz"
      sha256 "b3e0a9dbc922f3802702a55a1869ad2c2e4f4dc935d8a9d1b26c3612668dff43"
    end
    on_intel do
      url "https://github.com/roc-lang/roc/releases/download/0.1.0_RC1/roc-linux_x86_64-0.1.0_RC1.tar.gz"
      sha256 "043c426ea85dcdbd427951eaed246f0c10c171d988f2598782233a6dae43379d"
    end
  end

  # `brew test` runs this revision's CI script on the examples that pin this formula's Roc version.
  # Follows roc-lang.org's examples.json once its examples pin this version.
  resource "examples" do
    url "https://github.com/roc-lang/examples/archive/96a3521dc8cc41abd47e8f3d79942062f8a8f261.tar.gz"
    sha256 "eae6a55abade2f7911dad0c68631121eda4b4ceb13b69d224c5a59cb8b364666"
  end

  def install
    # roc links against the `darwin` sysroot next to its symlink-resolved path, so keep them together.
    libexec.install "roc"
    libexec.install "darwin" if OS.mac?
    bin.install_symlink libexec/"roc"
    prefix.install "legal_details"
  end

  test do
    assert_equal "Roc compiler version #{version}", shell_output("#{bin}/roc version").strip

    resource("examples").stage testpath
    # Each example pins its Roc version in its header; only those pinning this release must pass with it.
    # Headers spell the release 0.1.0_RC1 as 0.1.0-RC1.
    pin = "roc: \"#{version.to_s.tr("_", "-")}\""
    examples = (testpath/"examples").children.select do |dir|
      dir.glob("**/*.roc").any? { |file| file.read.include?(pin) }
    end
    refute_empty examples, "no example pins #{pin}"
    ENV["ROC"] = bin/"roc"
    system "bash", "ci_scripts/all_tests.sh", *examples.map { |dir| dir.basename.to_s }
  end
end
