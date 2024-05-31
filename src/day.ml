(*
 * SPDX-FileCopyrightText: 2016 - 2024 Richard Mortier <mort@cantab.net>
 *
 * SPDX-License-Identifier: ISC
 *)

open CalendarLib
open Astring

let of_string = function
  | "Mon" -> Date.Mon
  | "Tue" -> Date.Tue
  | "Wed" -> Date.Wed
  | "Thu" -> Date.Thu
  | "Fri" -> Date.Fri
  | "Sat" -> Date.Sat
  | "Sun" -> Date.Sun
  | _ as s -> invalid_arg ("invalid day: " ^ s)

let to_string d = d |> Printer.short_name_of_day |> String.with_range ~len:2
