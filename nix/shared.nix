{ compiler ? "ghc843", coverage ? false, system ? builtins.currentSystem }:

let
  fetchNixpkgs = import ./fetchNixpkgs.nix;

  mass = function: names: haskellPackagesNew: haskellPackagesOld:
    let
      toNameValue = name: {
        inherit name;

        value = function haskellPackagesOld."${name}";
      };

    in
      builtins.listToAttrs (map toNameValue names);

  overlayShared = pkgsNew: pkgsOld: {
    logo = {
      bash =
        pkgsNew.fetchurl {
          url    = "https://raw.githubusercontent.com/odb/official-bash-logo/master/assets/Logos/Icons/PNG/128x128.png";
          sha256 = "0fybbp6hbqrfw80fbk55bnykzda0m7x4vk38i80bjlmfbrkfvild";
        };

      clojure =
        pkgsNew.fetchurl {
          url    = "https://upload.wikimedia.org/wikipedia/commons/5/5d/Clojure_logo.svg";
          sha256 = "0mrjzv690g9mxljzxsvay8asyr8vlxhhs9smmax7mp3psd49b43g";
        };

      dhallLarge =
        pkgsNew.fetchurl {
          url    = "https://raw.githubusercontent.com/dhall-lang/dhall-lang/8bab26f9515cc1007025e0ab4b4e7dd6e95a7103/img/dhall-logo.png";
          sha256 = "0j6sfvm4kxqb2m6s1sv9qag7m30cibaxpphprhaibp9s9shpra4p";
        };

      dhallSmall =
        pkgsNew.fetchurl {
          url    = "https://raw.githubusercontent.com/dhall-lang/dhall-lang/8bab26f9515cc1007025e0ab4b4e7dd6e95a7103/img/dhall-icon.png";
          sha256 = "1lly3yb5szl9n3hszsfzv2mil98cvlidrzyci7vs4wi461s9bhxi";
        };

      github = pkgsNew.callPackage ./githubLogo.nix { };

      haskell =
        pkgsNew.fetchurl {
          url    = "https://wiki.haskell.org/wikiupload/4/4a/HaskellLogoStyPreview-1.png";
          sha256 = "0g26j7vx34m46mwp93qgg3q5x8pfdq2j1ch0vxz5gj0nk3b8fxda";
        };

      kubernetes =
        pkgsNew.fetchurl {
          url    = "https://raw.githubusercontent.com/kubernetes/kubernetes/7839fe38620508eb0651930cb0e1acb8ea367842/logo/logo.svg";
          sha256 = "0kp6idffg9k52ycgv5zkg9n08pfldzsy0fzhwsrb2f7cvrl6fpw4";
        };

      nix =
        pkgsNew.fetchurl {
          url    = "https://nixos.org/logo/nix-wiki.png";
          sha256 = "1hrz7wr7i0b2bips60ygacbkmdzv466lsbxi22hycg42kv4m0173";
        };

      json =
        pkgsNew.fetchurl {
          url    = "https://upload.wikimedia.org/wikipedia/commons/c/c9/JSON_vector_logo.svg";
          sha256 = "1hqd1qh35v9magjp3rbsw8wszk2wn3hkz981ir49z5cyf11jnx95";
        };

      stackOverflow =
        pkgsNew.fetchurl {
          url    = "https://cdn.sstatic.net/Sites/stackoverflow/company/img/logos/so/so-icon.svg";
          sha256 = "0i84h23ax197f3hwh0hqm6yjvvnpcjyhd6nkyy33z6x10dh8v4z3";
        };


      twitter = pkgsNew.callPackage ./twitterLogo.nix { };

      yaml =
        pkgsNew.fetchurl {
          url    = "https://raw.githubusercontent.com/yaml/yaml-spec/a6f764e13de58d5f753877f588a01b35dc9a5168/logo.png";
          sha256 = "12grgaxpqi755p2rnvw3x02zc69brpnzx208id1f0z42w387j4hi";
        };
    };

    dhall-sdist =
      let
        predicate = path: type:
          let
            base = baseNameOf path;

          in
             !( pkgsNew.lib.hasSuffix ".nix" base
             || base == "dist"
             || base == "result"
             || base == ".git"
             );

        src = builtins.filterSource predicate ../dhall;

      in
        pkgsNew.callPackage (import ./dhall-sdist.nix src) { };

    haskell = pkgsOld.haskell // {
      packages = pkgsOld.haskell.packages // {
        "${compiler}" = pkgsOld.haskell.packages."${compiler}".override (old: {
            overrides =
              let
                applyCoverage = drv:
                  if coverage
                  then
                    pkgsNew.haskell.lib.overrideCabal
                      (pkgsNew.haskell.lib.doCoverage
                        (pkgsNew.haskell.lib.doCheck drv)
                      )
                      (old: {
                          postInstall = (old.postInstall or "") + ''
                            ${pkgsNew.coreutils}/bin/mkdir --parents $out/nix-support
                            ${pkgsNew.coreutils}/bin/ln --symbolic $out/share/hpc/vanilla/html/dhall-* "$out/share/hpc/vanilla/html/dhall"
                            ${pkgsNew.coreutils}/bin/echo "report coverage $out/share/hpc/vanilla/html/dhall/hpc_index.html" >> $out/nix-support/hydra-build-products
                          '';
                        }
                      )
                  else
                    pkgsNew.haskell.lib.dontCheck drv;

                failOnAllWarnings = drv:
                  # Older versions of GHC incorrectly detect non-exhaustive
                  # pattern matches
                  if compiler == "ghc7103" || compiler == "ghcjs"
                  then drv
                  else pkgsNew.haskell.lib.failOnAllWarnings drv;

                dontCheckExtension =
                  mass pkgsNew.haskell.lib.dontCheck [
                    "aeson"
                    "base-compat-batteries"
                    "comonad"
                    "conduit"
                    "distributive"
                    "doctest"
                    "Glob"
                    "half"
                    "http-types"
                    "megaparsec"
                    "prettyprinter"
                    "prettyprinter-ansi-terminal"
                    # https://github.com/well-typed/cborg/issues/172
                    "serialise"
                    "semigroupoids"
                    "unordered-containers"
                    "yaml"
                  ];

                failOnAllWarningsExtension =
                  mass pkgsNew.haskell.lib.failOnAllWarnings [
                    "dhall"
                    "dhall-bash"
                    "dhall-json"
                    "dhall-text"
                  ];

                extension =
                  haskellPackagesNew: haskellPackagesOld: {
                    dhall =
                      applyCoverage
                        (haskellPackagesNew.callCabal2nix
                          "dhall"
                          pkgsNew.dhall-sdist
                          { }
                        );

                    dhall-bash =
                      haskellPackagesNew.callCabal2nix
                        "dhall-bash"
                        ../dhall-bash
                        { };

                    dhall-json =
                      haskellPackagesNew.callCabal2nix
                        "dhall-json"
                        ../dhall-json
                        { };

                    dhall-text =
                      haskellPackagesNew.callCabal2nix
                        "dhall-text"
                        ../dhall-text
                        { };

                    dhall-try =
                      pkgsNew.haskell.lib.overrideCabal
                        (haskellPackagesNew.callCabal2nix
                          "dhall-try"
                          (builtins.filterSource
                            (path: _: baseNameOf path != "index.html")
                            ../dhall-try
                          )
                          { }
                        )
                        (old: {
                            postInstall = (old.postInstall or "") + ''
                              ${pkgsNew.closurecompiler}/bin/closure-compiler $out/bin/dhall-try.jsexe/all.js --jscomp_off=checkVars --externs=$out/bin/dhall-try.jsexe/all.js.externs > $out/bin/dhall-try.jsexe/all.min.js
                            '';
                          }
                        );
                  };

              in
                pkgsNew.lib.fold
                  pkgsNew.lib.composeExtensions
                  (old.overrides or (_: _: {}))
                  [ (pkgsNew.haskell.lib.packagesFromDirectory { directory = ./.; })
                    dontCheckExtension
                    failOnAllWarningsExtension
                    extension
                  ];
          }
        );
      };
    };

    npm = pkgsNew.callPackage ./npm { };

    jQuery =
      pkgsNew.fetchurl {
        url    = "https://code.jquery.com/jquery-3.3.1.min.js";
        sha256 = "1vq2bp290rhby5l09dv5khqwv3ysnzbddggbgk6m4hl9y9pl42hn";
      };

    twitterBootstrap = pkgsNew.callPackage ./twitterBootstrap.nix { };

    try-dhall = pkgsNew.runCommand "try-dhall" {} ''
      ${pkgsNew.coreutils}/bin/mkdir $out
      ${pkgsNew.coreutils}/bin/mkdir $out/{css,img,js}
      ${pkgsNew.coreutils}/bin/cp ${../dhall-try/index.html} $out/index.html
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.nodePackages.js-yaml}/lib/node_modules/js-yaml/dist/js-yaml.min.js $out/js
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.jQuery} $out/js/jquery.min.js
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.twitterBootstrap}/js/bootstrap.min.js $out/js
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.twitterBootstrap}/js/bootstrap.min.js.map $out/js
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.twitterBootstrap}/css/bootstrap.min.css $out/css
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.npm.codemirror}/lib/node_modules/codemirror/lib/codemirror.js $out/js
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.npm.codemirror}/lib/node_modules/codemirror/mode/haskell/haskell.js $out/js
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.npm.codemirror}/lib/node_modules/codemirror/mode/javascript/javascript.js $out/js
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.npm.codemirror}/lib/node_modules/codemirror/mode/yaml/yaml.js $out/js
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.npm.codemirror}/lib/node_modules/codemirror/lib/codemirror.css $out/css
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.haskell.packages.ghcjs.dhall-try}/bin/dhall-try.jsexe/all.min.js $out/js
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.dhall.prelude} $out/Prelude
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.bash} $out/img/bash-logo.png
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.clojure} $out/img/clojure-logo.svg
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.dhallLarge} $out/img/dhall-large-logo.png
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.dhallSmall} $out/img/dhall-small-logo.png
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.github}/PNG/GitHub-Mark-32px.png $out/img/github-logo.png
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.haskell} $out/img/haskell-logo.png
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.kubernetes} $out/img/kubernetes-logo.svg
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.json} $out/img/json-logo.svg
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.nix} $out/img/nix-logo.png
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.stackOverflow} $out/img/stack-overflow-logo.svg
      ${pkgsNew.coreutils}/bin/ln --symbolic '${pkgsNew.logo.twitter}/Twitter Logos/Twitter Logos/Twitter_Logo_Blue/Twitter_Logo_Blue.svg' $out/img/twitter-logo.svg
      ${pkgsNew.coreutils}/bin/ln --symbolic ${pkgsNew.logo.yaml} $out/img/yaml-logo.png
      ${pkgsNew.coreutils}/bin/mkdir $out/nix-support
      ${pkgsNew.coreutils}/bin/echo "doc none $out/index.html" > $out/nix-support/hydra-build-products
    '';

    tarball-try-dhall = pkgsStaticLinux.releaseTools.binaryTarball rec {
      src = pkgsNew.try-dhall;

      installPhase = ''
        releaseName=try-dhall
        ${pkgsNew.coreutils}/bin/install --target-directory "$TMPDIR/inst/try-dhall/"    -D $src/index.html
        ${pkgsNew.coreutils}/bin/install --target-directory "$TMPDIR/inst/try-dhall/img" -D $src/img/*
        ${pkgsNew.coreutils}/bin/install --target-directory "$TMPDIR/inst/try-dhall/css" -D $src/css/*
        ${pkgsNew.coreutils}/bin/install --target-directory "$TMPDIR/inst/try-dhall/js"  -D $src/js/*
      '';
    };
  };

  overlayCabal2nix = pkgsNew: pkgsOld: {
    haskellPackages = pkgsOld.haskellPackages.override (old: {
        overrides =
          let
            extension =
              haskellPackagesNew: haskellPackagesOld: {
                # `cabal2nix` requires a newer version of `hpack`
                hpack =
                  haskellPackagesOld.hpack_0_29_6;
              };

          in
            pkgsNew.lib.composeExtensions
              (old.overrides or (_: _: {}))
              extension;
      }
    );
  };

  overlayGHC7103 = pkgsNew: pkgsOld: {
    haskell = pkgsOld.haskell // {
      packages = pkgsOld.haskell.packages // {
        "${compiler}" = pkgsOld.haskell.packages."${compiler}".override (old: {
            overrides =
              let
                extension =
                  haskellPackagesNew: haskellPackagesOld: {
                    # Newer version of these packages have bounds incompatible
                    # with GHC 7.10.3
                    lens-family-core =
                      haskellPackagesOld.lens-family-core_1_2_1;

                    memory =
                      haskellPackagesOld.memory_0_14_16;

                    basement =
                      haskellPackagesOld.basement_0_0_6;

                    foundation =
                      haskellPackagesOld.foundation_0_0_19;

                    # Most of these fixes are due to certain dependencies being
                    # hidden behind a conditional compiler version directive, so
                    # they aren't included by default in the default Hackage
                    # package set (which was generated for `ghc-8.4.3`)
                    base-compat-batteries =
                      pkgsNew.haskell.lib.addBuildDepends
                        haskellPackagesOld.base-compat-batteries
                        [ haskellPackagesNew.bifunctors
                          haskellPackagesNew.fail
                        ];

                    cborg =
                      pkgsNew.haskell.lib.addBuildDepends
                        haskellPackagesOld.cborg
                        [ haskellPackagesNew.fail
                          haskellPackagesNew.semigroups
                        ];

                    contravariant =
                      pkgsNew.haskell.lib.addBuildDepends
                        haskellPackagesOld.contravariant
                        [ haskellPackagesNew.fail
                          haskellPackagesNew.semigroups
                        ];

                    dhall =
                      pkgsNew.haskell.lib.addBuildDepends
                        haskellPackagesOld.dhall
                        [ haskellPackagesNew.doctest
                          haskellPackagesNew.mockery
                        ];

                    megaparsec =
                      pkgsNew.haskell.lib.addBuildDepend
                        haskellPackagesOld.megaparsec
                        haskellPackagesNew.fail;

                    generic-deriving =
                      pkgsNew.haskell.lib.dontCheck
                        haskellPackagesOld.generic-deriving;

                    prettyprinter =
                      pkgsNew.haskell.lib.addBuildDepend
                        haskellPackagesOld.prettyprinter
                        haskellPackagesNew.semigroups;

                    transformers-compat =
                      pkgsNew.haskell.lib.addBuildDepend
                        haskellPackagesOld.transformers-compat
                        haskellPackagesNew.generic-deriving;

                    # For some reason, `Cabal-1.22.5` does not respect the
                    # `buildable: False` directive for the executable section
                    # even when configured with `-f -cli`.  Fixing this requires
                    # patching out the executable section of `wcwidth` in order
                    # to avoid pulling in some extra dependencies which cause a
                    # a dependency cycle.
                    wcwidth =
                      pkgsNew.haskell.lib.appendPatch
                        haskellPackagesOld.wcwidth ./wcwidth.patch;
                  };

              in
                pkgsNew.lib.composeExtensions
                  (old.overrides or (_: _: {}))
                  extension;
          }
        );
      };
    };
  };

  nixpkgs = fetchNixpkgs {
    rev = "1d4de0d552ae9aa66a5b8dee5fb0650a4372d148";

    sha256 = "09qx58dp1kbj7cpzp8ahbqfbbab1frb12sh1qng87rybcaz0dz01";

    outputSha256 = "0xpqc1fhkvvv5dv1zmas2j1q27mi7j7dgyjcdh82mlgl1q63i660";
  };

  pkgs = import nixpkgs {
    inherit system;

    config = {};

    overlays =
          [ overlayShared overlayCabal2nix ]
      ++  (if compiler == "ghc7103" then [ overlayGHC7103 ] else []);
  };

  overlayStaticLinux = pkgsNew: pkgsOld: {
    cabal_patched_src = pkgsNew.fetchFromGitHub {
      owner = "nh2";
      repo = "cabal";
      rev = "748f07b50724f2618798d200894f387020afc300";
      sha256 = "1k559m291f6spip50rly5z9rbxhfgzxvaz64cx4jqpxgfhbh2gfs";
    };

    Cabal_patched_Cabal_subdir = pkgsNew.stdenv.mkDerivation {
      name = "cabal-dedupe-src";
      buildCommand = ''
        cp -rv ${pkgsNew.cabal_patched_src}/Cabal/ $out
      '';
    };

    haskell = pkgsOld.haskell // {
      lib = pkgsOld.haskell.lib // {
        useFixedCabal = drv: pkgsNew.haskell.lib.overrideCabal drv (old: {
            setupHaskellDepends =
              (old.setupHaskellDepends or []) ++ [
                pkgsNew.haskell.packages."${compiler}".Cabal_patched
              ];

            libraryHaskellDepends =
              (old.libraryHaskellDepends or []) ++ [
                pkgsNew.haskell.packages."${compiler}".Cabal_patched
              ];
          }
        );

      statify = drv:
        pkgsNew.lib.foldl pkgsNew.haskell.lib.appendConfigureFlag
          (pkgsNew.haskell.lib.disableLibraryProfiling
            (pkgsNew.haskell.lib.disableSharedExecutables
              (pkgsNew.haskell.lib.useFixedCabal
                 (pkgsNew.haskell.lib.justStaticExecutables drv)
              )
            )
          )
          [ "--enable-executable-static"
            "--extra-lib-dirs=${pkgsNew.gmp6.override { withStatic = true; }}/lib"
            "--extra-lib-dirs=${pkgsNew.zlib.static}/lib"
            "--extra-lib-dirs=${pkgsNew.ncurses.override { enableStatic = true; }}/lib"
          ];
      };

      packages = pkgsOld.haskell.packages // {
        "${compiler}" = pkgsOld.haskell.packages."${compiler}".override (old: {
            overrides =
              let
                extension =
                  haskellPackagesNew: haskellPackagesOld: {
                    Cabal_patched =
                      haskellPackagesNew.callCabal2nix
                        "Cabal"
                        pkgsNew.Cabal_patched_Cabal_subdir
                        { };

                    dhall-static =
                        pkgsNew.haskell.lib.statify haskellPackagesOld.dhall;

                    dhall-bash-static =
                        pkgsNew.haskell.lib.statify haskellPackagesOld.dhall-bash;

                    dhall-json-static =
                        pkgsNew.haskell.lib.statify haskellPackagesOld.dhall-json;

                    dhall-text-static =
                        pkgsNew.haskell.lib.statify haskellPackagesOld.dhall-text;
                  };

              in
                pkgsNew.lib.composeExtensions
                  (old.overrides or (_: _: {}))
                  extension;
          }
        );
      };
    };
  };

  nixpkgsStaticLinux = fetchNixpkgs {
    owner = "nh2";

    rev = "925aac04f4ca58aceb83beef18cb7dae0715421b";

    sha256 = "0zkvqzzyf5c742zcl1sqc8009dr6fr1fblz53v8gfl63hzqwj0x4";

    outputSha256 = "1zr8lscjl2a5cz61f0ibyx55a94v8yyp6sjzjl2gkqjrjbg99abx";
  };

  pkgsStaticLinux = import nixpkgsStaticLinux {
    config = {};
    overlays = [ overlayShared overlayStaticLinux ];
    system = "x86_64-linux";
  };

  # Derivation that trivially depends on the current directory so that Hydra's
  # pull request builder always posts a GitHub status on each revision
  pwd = pkgs.runCommand "pwd" { here = ../.; } "touch $out";

  makeTarball = name:
    pkgsStaticLinux.releaseTools.binaryTarball rec {
      src = pkgsStaticLinux.pkgsMusl.haskell.packages."${compiler}"."${name}-static";

      installPhase = ''
        releaseName=${name}
        ${pkgsStaticLinux.coreutils}/bin/install --target-directory "$TMPDIR/inst/bin" -D $src/bin/*
      '';
    };

  toShell = drv:
    if compiler == "ghcjs"
    then
        # `doctest` doesn't work with `ghcjs`
        (pkgs.haskell.lib.dontCheck drv).env
    else
        # Benchmark dependencies aren't added by default
        (pkgs.haskell.lib.doBenchmark drv).env;

in
  rec {
    inherit pwd;

    tarball-dhall      = makeTarball "dhall"     ;
    tarball-dhall-bash = makeTarball "dhall-bash";
    tarball-dhall-json = makeTarball "dhall-json";
    tarball-dhall-text = makeTarball "dhall-text";

    inherit (pkgs) tarball-try-dhall try-dhall-server try-dhall;

    inherit (pkgs.haskell.packages."${compiler}") dhall dhall-bash dhall-json dhall-text dhall-try;

    inherit (pkgs.releaseTools) aggregate;

    shell-dhall      = toShell pkgs.haskell.packages."${compiler}".dhall     ;
    shell-dhall-bash = toShell pkgs.haskell.packages."${compiler}".dhall-bash;
    shell-dhall-json = toShell pkgs.haskell.packages."${compiler}".dhall-json;
    shell-dhall-text = toShell pkgs.haskell.packages."${compiler}".dhall-text;
    shell-dhall-try  = toShell pkgs.haskell.packages."${compiler}".dhall-try ;

    test-dhall =
      pkgs.mkShell
        { buildInputs =
            [ (pkgs.haskell.packages."${compiler}".ghcWithPackages
                (pkgs: [ pkgs.dhall ])
              )
            ];
        };
  }
