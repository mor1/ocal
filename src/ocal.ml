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

let months range =
  let parse ?(rh=false) s =
    let s = String.Ascii.capitalize s in
    let date =
      Printer.Date.(
        try
          (* monthyear *)
          from_fstring "%d%b%Y" ((if rh then "28" else "01")^s)
        with Invalid_argument _ -> begin
            (* year *)
            try from_fstring "%d%b%Y" ((if rh then "31Dec" else "01Jan")^s)
            with Invalid_argument _ -> begin
                (* month *)
                let thisyear = string_of_int Date.(year (today ())) in
                from_fstring "%d%b%Y" ((if rh then "28" else "01")^s^thisyear)
              end
          end
      )
    in
    match rh with
    | true ->
      Date.(make (year date) (int_of_month (month date)) (days_in_month date))
    | false ->
      date
  in
  match String.cuts ~sep:"-" range with
  | [st; nd] -> begin
      let st = parse st in
      let nd = parse ~rh:true nd in

      let rec aux d nd acc =
        match Date.compare d nd with
        | n when n > 0 (*  > *) -> List.rev acc
        | n            (* <= *) ->
          let d' = (Date.next d `Month) in
          aux d' nd (d::acc)
      in
      aux st nd []
    end
  | [st] -> [ parse st ]
  | _ -> invalid_arg ("invalid date range: " ^ range)

let cal plain today ncols sep firstday range =
  let today = Printer.Date.to_string today in
  let firstday = Printer.name_of_day firstday in
  Printf.printf "plain=%b\n\
                 today=%s\n\
                 ncols=%d\n\
                 sep='%s'\n\
                 firstday=%s\n\
                 range=%s\n%!"
    plain today ncols sep firstday range
  ;
  Printf.printf "months=%s\n%!"
    (String.concat ~sep:"," (months range |> List.map Printer.Date.to_string))

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
        `Ok (day |> String.Ascii.capitalize |> day_of_string)
      with
      | Invalid_argument s -> `Error s
    in
    parse, fun ppf p -> Format.fprintf ppf "%s" (Printer.short_name_of_day p)
  in
  let doc = "Format with $(docv) as first day-of-week." in
  Arg.(value & opt aux (Date.Mon) & info ["f"; "firstday"] ~docv:"ddd" ~doc)

let plain =
  let doc = "Turn off highlighting." in
  Arg.(value & flag & info ["p"; "plain"] ~doc)

let range =
 let doc = "RANGE." in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"RANGE" ~doc)

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
  Term.(const cal $ plain $ today $ ncols $ sep $ firstday $ range),
  Term.info Config.command ~version:Config.version ~doc ~man

(* go! *)

let () =
  match Term.eval cmd with
  | `Error _ -> exit 1
  | _ -> exit 0
