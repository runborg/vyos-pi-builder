#!/bin/bash -e

mkdir -p patches/kernel
cd patches/kernel

rm -rf 0[012][0123456789]-*.patch


curl https://github.com/frank-w/BPI-Router-Linux/commit/21be1cc5a182c88b495817ac62bbbea4624e9dcb.patch --fail --silent --show-error -o 001-mt7988_thermal_compatible.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/283f2b40ef0776d9ede58972aaaa9e0093790f7d.patch --fail --silent --show-error -o 002-mt7988_thermal_coeff_configurable.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/5a7801c9f483745cb51283dc53bce4671c25143f.patch --fail --silent --show-error -o 003_mt7988_thermal_support_support.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/0b3b5a61fa9270f11882429c38499a8defc0bab4.patch --fail --silent --show-error -o 004-mt7988_resets.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/1d9128507d95ed3ae905094869e2244a78cc4574.patch --fail --silent --show-error -o 005-add_build_scripts_and_defconfigs.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/d15f706179bce0ad39bd4f8963db03828efe36e0.patch --fail --silent --show-error -o 006-mt7986_add_dtbs_with_applied_overlays.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/5e5e7e33fc3bf0ebfe33717797b40dab797b7eea.patch --fail --silent --show-error -o 007-build-sh_allow_install_itb_for_r2pro.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/ed945b3d8a8859bfdb598194d81ec0d7d82f2ff9.patch --fail --silent --show-error -o 008-build-sh_fix_install_flag_for_r2pro.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/9f8125fa8efab0b475ba322f2d203f42e4397bb3.patch --fail --silent --show-error -o 009-build-sh_change_uenv_for_r2pro.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/8b8bd1354e643bf2c041b046200fd026f5100c3f.patch --fail --silent --show-error -o 010-build-sh_dont_use_uimage_prefix.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/512366ca3d599c60104b25a77142b5a2c5853696.patch --fail --silent --show-error -o 011-r2pro_fix_bootup_after_MFD_RK808_rename.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/66cf4314046ab5a7aa6b48dfc1f1c12871ddbbf5.patch --fail --silent --show-error -o 012-r2_fix_tailing_spaces.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/a722a9733e6063e2de08590ea33876d389201da2.patch --fail --silent --show-error -o 013-build-sh_copy_all_versions_of_dtb_files.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/eda8a51e2be88e8a83b2abf0f8dba49fed1afe0d.patch --fail --silent --show-error -o 014-mt7986_revert_applied_overlays_for_bpi-r3.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/fe2109c41c2ae05d77fe6898309f63e2a6da2b93.patch --fail --silent --show-error -o 015-mt7986_fix_emmc_hs400_mode_without_uboot_initialization.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/8f4d808fb9b3f173349030776bff1a41d27b150f.patch --fail --silent --show-error -o 016-mt7986_define_3w_max_power_to_both_sfp_on_bpi-r3.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/c704d9656bef69caf69e926b3f51d7d250bf4e1f.patch --fail --silent --show-error -o 017-mt7986_change_cooling_trips.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/acef1dc1c0b715cc12871e2bfb4aaddcf339d4c3.patch --fail --silent --show-error -o 018-mt7986_add_dtbs_with_applied_overlays_for_bpi-r3.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/8426ba3179e7d4a8e8aa3d7515216eb773a4bd2a.patch --fail --silent --show-error -o 019-mt7986_add_overlay_for_sata_power_socket_on_bpi-r3.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/f19799c4f6c04dd09cc9e20684bb4d4eb13e2beb.patch --fail --silent --show-error -o 020-mt7986_fix_temperature_sensor_on_mt7986.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/d320876eee345b9261e5aa081c5d6846a8bc3722.patch --fail --silent --show-error -o 021-mt7623_swap_mmc_and_put_uart2_first.patch
curl https://github.com/frank-w/BPI-Router-Linux/commit/530fe7eba9e99d40ed5242dc7c8dae0d9f5af0da.patch --fail --silent --show-error -o 022-mt7986_change_defconfig_wmac_config_name.patch
