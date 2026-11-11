# Interim formula: installs prebuilt binaries from roc-lang/nightlies until Roc has
# a stable release that can go to homebrew-core. Kept in sync with the release in
# roc-lang.org's install_roc.sh by .github/workflows/update.yml.
class Roc < Formula
  desc "Fast, friendly, functional programming language"
  homepage "https://www.roc-lang.org"
  version "2026-11-09-9e85de7"
  license "UPL-1.0"

  uses_from_macos "expect" => :test

  on_macos do
    # macOS 15 is the oldest version Roc is tested on.
    depends_on macos: :sequoia

    on_arm do
      url "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-11-09-9e85de7/roc_nightly-macos_apple_silicon-2026-11-09-9e85de7.tar.gz"
      sha256 "0e12e15c1c1d0af817c1f27b0f103a6502c2b3aea587f1de7d7df312642d74d3"
    end
    on_intel do
      url "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-11-09-9e85de7/roc_nightly-macos_x86_64-2026-11-09-9e85de7.tar.gz"
      sha256 "1bfde3c6000910153c062897914589c35dc6e9767f3a23f7f7e23cd0264f58f5"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-11-09-9e85de7/roc_nightly-linux_arm64-2026-11-09-9e85de7.tar.gz"
      sha256 "9c12d85abce8aa36daed9ffe04c75fe00c67b0fc939647899493500a1a3b5eff"
    end
    on_intel do
      url "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-11-09-9e85de7/roc_nightly-linux_x86_64-2026-11-09-9e85de7.tar.gz"
      sha256 "9d2480e900bee27cae0974266c088f43e8e2ceaa6543c2be7314b7bdd2b7891d"
    end
  end

  # The examples revision that roc-lang.org's examples.json pins; `brew test` runs its CI script
  # on the examples that pin this formula's Roc version.
  resource "examples" do
    url "https://github.com/roc-lang/examples/archive/fd93512e8fd5d19c5ef2cd69f7d5e036e6b106a3.tar.gz"
    sha256 "7e529f0f9643b163fae2626c99d12287c417905eb7a80a01836cc1f13f951fae"
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
