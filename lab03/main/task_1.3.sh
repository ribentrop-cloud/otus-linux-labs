#!/bin/sh
# Убираем ненужные lv и vg
yes | lvremove /dev/vg_temproot/lv_temproot
yes | vgremove /dev/vg_temproot
# Первое задание выполнено!

