{ addRtp, pkgs, treeSitterGrammars, ...}:
final: prev: {
  gitsigns-nvim = prev.gitsigns-nvim.overrideAttrs (old: {
    dependencies = with final; [ plenary-nvim ];
  });

  # plenary-nvim = super.toVimPlugin(luaPackages.plenary-nvim);

  plenary-nvim = prev.plenary-nvim.overrideAttrs (old: {
    postInstall = ''
      chmod -R u+w $out
      cd $out
      patch -p1 <${./plenary-border-hack.patch}
      sed -Ei $out/lua/plenary/curl.lua \
          -e 's@(command\s*=\s*")curl(")@\1${pkgs.curl}/bin/curl\2@'
    '';
  });

  popup-nvim = prev.popup-nvim.overrideAttrs (old: {
    postInstall = ''
      chmod -R u+w $out
      cd $out
      patch -p1 <${./popup-nvim-border-hack.patch}
    '';
  });

  nvim-treesitter = prev.nvim-treesitter.overrideAttrs (old: {
    passthru.withPlugins =
      grammarFn: final.nvim-treesitter.overrideAttrs (_: {
        postInstall =
          let
            grammars = treeSitterGrammars grammarFn;
          in ''
            chmod  -R u+w $out
            rm -rf $out/parser
            ln -s ${grammars} $out/parser
          '';
      });
  });

  telescope-nvim = prev.telescope-nvim.overrideAttrs (old: {
    dependencies = with final; [ plenary-nvim popup-nvim ];
    postInstall = ''
      chmod u+w $out -R
      cd $out
      patch -p1 <${./telescope-nvim-border-hack.patch}
    '';
  });

  telescope-fzf-nvim = prev.telescope-fzf-nvim.overrideAttrs (old: {
    dependencies = with final; [ telescope-nvim ];
    postInstall = ''
      chmod u+w $out -R
      cd $out
      make
    '';
  });

  fzf-vim = prev.fzf-vim.overrideAttrs (old: {
    dependencies = with final; [ fzfWrapper ];
  });

  fzfWrapper = addRtp "." (pkgs.stdenv.mkDerivation {
    name = "vimplugin-fzfWrapper";
    pname = "fzf";
    unpackPhase = ":";
    buildPhase = ":";
    configurePhase = ":";
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      cp -r "${pkgs.fzf}/share/vim-plugins/fzf/plugin/"* "$out"
      ln -s ${pkgs.fzf}/bin/fzf $out/bin/fzf
      runHook postInstall
    '';
  });

  direnv-vim = prev.direnv-vim.overrideAttrs (oa: {
    preFixup = oa.preFixup or "" + ''
      substituteInPlace $out/autoload/direnv.vim \
        --replace "let s:direnv_cmd = get(g:, 'direnv_cmd', 'direnv')" \
          "let s:direnv_cmd = get(g:, 'direnv_cmd', '${pkgs.lib.getBin pkgs.direnv}/bin/direnv')"
    '';
  });

  guihua = prev.guihua.overrideAttrs (old: {
    postInstall = ''
      chmod u+w $out -R
      cd $out/lua/fzy
      make
    '';
  });
}
