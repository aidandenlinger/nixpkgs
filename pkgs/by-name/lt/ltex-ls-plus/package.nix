{
  lib,
  fetchFromGitHub,
  python3,
  cacert,
  jre_headless,
  makeWrapper,
  maven,
  jvmOptions ? [ ],
}:

maven.buildMavenPackage (finalAttrs: {
  pname = "ltex-ls-plus";
  version = "18.7.0";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "ltex-plus";
    repo = "ltex-ls-plus";
    tag = finalAttrs.version;
    hash = "sha256-yn3f7VlQksOuQoEp4NfBMjtrFU/6mc+wx7X2G3qXaPQ=";
  };

  mvnHash = "sha256-i2hFBLimW/8gkOWtP6BaxY74p/oOuFdzHysWnLFRkjQ=";

  nativeBuildInputs = [
    # The maven build runs python/java scripts and they need certs for downloads
    cacert
    python3
    jre_headless

    makeWrapper
  ];

  # Allow access to the Kotlin compile daemon
  __darwinAllowLocalNetworking = true;

  installPhase =
    let
      java_opts = lib.optionalString (
        jvmOptions != [ ]
      ) ''--set JAVA_OPTS "${lib.escapeShellArgs jvmOptions}"'';
    in
    ''
      runHook preInstall

      mkdir target/unpacked
      tar xf target/ltex-ls-plus-${finalAttrs.version}.tar.gz -C target/unpacked --strip-components=1

      mkdir -p $out
      cp -rfv target/unpacked/{bin,lib} $out
      rm -fv $out/bin/.lsp-cli.json $out/bin/*.bat

      for file in $out/bin/{ltex-ls-plus,ltex-cli-plus}; do
        wrapProgram $file --set JAVA_HOME "${jre_headless}" ${java_opts}
      done

      runHook postInstall
    '';

  meta = {
    homepage = "https://ltex-plus.github.io/ltex-plus/";
    description = "LSP language server for LanguageTool";
    license = lib.licenses.mpl20;
    mainProgram = "ltex-cli-plus";
    maintainers = with lib.maintainers; [ FirelightFlagboy ];
    platforms = jre_headless.meta.platforms;
  };
})
