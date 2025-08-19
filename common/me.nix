{
  lib, ...
}:
{
  options.me = {
    username = lib.mkOption { type = lib.types.str; };
    email = lib.mkOption { type = lib.types.str; };
    sshKeys = lib.mkOption { type = lib.types.listOf lib.types.str; };
  };

  config.me = {
    username = "kate";
    email = "common@localcc.cc";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHWfBIxvY4c0Rdava/cAEa3qGUOxMSt4Cu0Ap7RtSK7"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1Ot5v9buwKeGkeULO3s+HPD4t1w9HF8bPahnrnGpGFROStg4VQGsWZ6yT+HudAERi95ndDdD+SfwmZ7v3ND8gq9EyEQAr9w7BdtTdCqcRVxDOzdfEL/QR90fg96PooDjzsJ/Hv3xtIjWRRHVasVVcNOvRimiBc2PtRZ63PODGQT+Nz334BQG8rS8AjH1uJESByuyISNIakyuZB+MNXJhp2m/Qt6RHm1Uyh0UFkVLvI3eXohAnbXspb082p30mKke0F3B2RPf7L7WRPdHzdCi3NboMGMQXGVtl2Qp8eAELMVg2cQyk6NGcJvJ66s/Z/97Wu7YQB4UONYYbf7rdLqmd0+r20qsh0D/I+5HV5QzY9zdLFi8vb2kHvheM9mpM+YDAnplVDIyWUe0CMYnj3eHEHPop/9beWiUhCJU0tba3K8izSFPzzxiFu0DWXER+xV0s+dFwJLY/WxgrL+4Z9WC2cWIFR2PKG3u9c/1KtGkMmQ3Wvvo6ObZkDGlOFEhXZikgt/AH8OmeyqoU0BG7Dj/OYzURXR3vZD2k7J6pE/PBaf7vazlLVBYCrBlKvXeIYfbGRWs1qorLAHX6smtK3sXlGyoA+FtRUKKL1ISSCxcnfa5MLk63VMbpviYUoIcoDTQFhlq+VgByX5E5KmnLtaCk26dn6bWMPCV5SQCyKVckqQ=="
    ];
  };
}
