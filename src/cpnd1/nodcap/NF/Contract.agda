module nodcap.NF.Contract where

open import Function using (_$_)
open import Data.Nat as ℕ using (ℕ; suc; zero)
open import Data.Pos as ℕ⁺
open import Data.List as L using (List; []; _∷_; _++_)
open import Data.Environment
open import nodcap.Base
open import nodcap.NF.Typing


-- Lemma:
--   We can contract n repetitions of A to an instance of ?[ n ] A,
--   by induction on n.
contract : {Γ : Environment} {A : Type} {n : ℕ⁺} →

  ⊢ⁿᶠ replicate⁺ n A ++ Γ →
  ----------------------
  ⊢ⁿᶠ ?[ n ] A ∷ Γ

contract {n = suc zero}    x
  = mk?₁ x
contract {n = suc (suc n)} x
  = cont {m = suc zero}
  $ exch (fwd [] (_ ∷ []))
  $ contract
  $ exch (bwd [] (replicate⁺ (suc n) _))
  $ mk?₁ x
