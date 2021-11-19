@echo off

cl65 -o out.nes -t nes main.asm
fceux out.nes