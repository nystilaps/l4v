(*
 * Copyright 2014, NICTA
 *
 * This software may be distributed and modified according to the terms of
 * the BSD 2-Clause license. Note that NO WARRANTY is provided.
 * See "LICENSE_BSD2.txt" for details.
 *
 * @TAG(NICTA_BSD)
 *)

theory MachineWords
imports "../../../CTranslation"
begin

type_synonym machine_word_len = "32"

type_synonym machine_word = "machine_word_len word"

abbreviation "machine_word_bytes \<equiv> 4 :: nat"

lemma of_nat_machine_word_bytes[simp]: "of_nat machine_word_bytes = 4"
  by simp

end