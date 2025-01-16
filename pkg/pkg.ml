#!/usr/bin/env ocaml

(*
 * SPDX-FileCopyrightText: 2024 Richard Mortier <mort@cantab.net>
 *
 * SPDX-License-Identifier: ISC
 *)
#use "topfind"

#require "topkg-jbuilder"

open Topkg

let publish = Pkg.publish ~artefacts:[ `Distrib ] ()
let () = Topkg_jbuilder.describe ~publish ()
