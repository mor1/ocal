(*
 * Copyright (c) 2016 Richard Mortier <mort@cantab.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Cmdliner
open Astring
open CalendarLib

let day_of_string = function
  | "Mon" -> Date.Mon
  | "Tue" -> Date.Tue
  | "Wed" -> Date.Wed
  | "Thu" -> Date.Thu
  | "Fri" -> Date.Fri
  | "Sat" -> Date.Sat
  | "Sun" -> Date.Sun
  | _ as s -> invalid_arg ("invalid day: " ^ s)

let cal nohighlight today years ncols sep firstday =
  let today = Printer.Date.to_string today in
  let firstday = Printer.name_of_day firstday in
  Printf.printf "nohighlight=%b\n\
                 today=%s\n\
                 years=%b\n\
                 ncols=%d\n\
                 sep='%s'\n\
                 firstday=%s\n%!"
    nohighlight today years ncols sep firstday

(* command line parsing *)

let today =
  let aux =
    let parse date =
      try
        `Ok (Printer.Date.from_string date)
      with
      | Invalid_argument _ ->
        try
          let date = Printer.Date.from_fstring "%y-%m-%d" date in
          (* [Calendar.Date.from_string "%y" xx] defaults to `Year 19xx *)
          `Ok Date.(add date (Period.year 100))
        with
        | Invalid_argument _ ->
          `Error ("invalid date string: " ^ date)
    in
    parse, fun ppf p -> Format.fprintf ppf "%s" (Printer.Date.to_string p)
  in
  let doc = "Set today's date." in
  Arg.(value & opt aux (Date.today ())
       & info ["t"; "today"] ~docv:"yyyy-mm-dd" ~doc)

let ncols =
  let doc = "Format across $(docv) columns." in
  Arg.(value & opt int 3 & info ["c"; "columns"] ~docv:"N" ~doc)

let sep =
  let doc = "Format using $(docv) as month separator." in
  Arg.(value & opt string "   " & info ["s"; "separator"] ~docv:"sep" ~doc)

let firstday =
  let aux =
    let parse day =
      try
        `Ok (day |> String.Ascii.lowercase |> day_of_string)
      with
      | Invalid_argument s -> `Error s
    in
    parse, fun ppf p -> Format.fprintf ppf "%s" (Printer.short_name_of_day p)
  in
  let doc = "Format with $(docv) as first day-of-week." in
  Arg.(value & opt aux (Date.Mon) & info ["f"; "firstday"] ~docv:"ddd" ~doc)

let years =
  let doc = "Interpret arguments as years." in
  Arg.(value & flag & info ["y"; "years"] ~doc)

let nohighlight =
  let doc = "Turn off highlighting." in
  Arg.(value & flag & info ["n"; "no-highlight"] ~doc)

let cmd =
  let doc = "pretty print calendar months" in
  let man = [
    `S "DESCRIPTION";
    `P "$(tname) -- pretty prints specified monthly calendars.";

    `S "SEE ALSO";
    `P "cal(1), ncal(1), calendar(3), strftime(3)";

    `S "HISTORY";
    `P
      "Translated from\
      \ https://github.com/mor1/python-scripts/blob/master/cal.py because I got\
      \ tired of the startup time. The Python version was written because I got\
      \ tired of the CLI.";

    `S "AUTHORS";
    `P "Richard Mortier <mort@cantab.net>.";

    `S "BUGS";
    `P "Report bugs at https://github.com/mor1/ocaml-cal/issues.";
  ]
  in
  Term.(const cal $ nohighlight $ today $ years $ ncols $ sep $ firstday),
  Term.info Config.command ~version:Config.version ~doc ~man

(* go! *)

let () =
  match Term.eval cmd with
  | `Error _ -> exit 1
  | _ -> exit 0
