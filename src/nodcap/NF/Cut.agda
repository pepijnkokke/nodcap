module nodcap.NF.Cut where

open import Algebra
open import Data.Environment
open import Data.Nat as ℕ using (ℕ; suc; zero)
open import Data.Pos as ℕ⁺
open import Data.List as L using (List; []; _∷_; _++_)
open import Data.List.Any as LA using (Any; here; there)
open import Data.List.Any.BagAndSetEquality as B
open import Data.Product as PR using (∃; _×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Function using (_$_; flip)
open import Function.Equality using (_⟨$⟩_)
open import Function.Inverse as I using ()
open import Relation.Binary.PropositionalEquality as P using (_≡_; _≢_)

open import nodcap.Base
open import nodcap.NF.Typing
open import nodcap.NF.Contract
open import nodcap.NF.Expand

open I.Inverse using (to; from)
private module ++ {a} {A : Set a} = Monoid (L.monoid A)

{-# TERMINATING #-}
-- Theorem:
--   Cut elimination.
mutual
  cut : {Γ Δ : Environment} {A : Type} →

    ⊢ⁿᶠ A ∷ Γ → ⊢ⁿᶠ A ^ ∷ Δ →
    ---------------------
    ⊢ⁿᶠ Γ ++ Δ

  cut {_} {Δ} {A = 𝟏} halt (wait y)
    = y
  cut {Γ} {_} {A = ⊥} (wait x) halt
    = P.subst ⊢ⁿᶠ_ (P.sym (proj₂ ++.identity Γ)) x
  cut {_} {Θ} {A = A ⊗ B} (send {Γ} {Δ} x y) (recv z)
    = P.subst ⊢ⁿᶠ_ (P.sym (++.assoc Γ Δ Θ))
    $ exch (swp [] Γ Δ)
    $ cut y
    $ exch (fwd [] Γ)
    $ cut x z
  cut {Θ} {_} {A = A ⅋ B} (recv x) (send {Γ} {Δ} y z)
    = P.subst ⊢ⁿᶠ_ (++.assoc Θ Γ Δ)
    $ cut (cut x y) z
  cut {Γ} {Δ} {A = A ⊕ B} (sel₁ x) (case y z)
    = cut x y
  cut {Γ} {Δ} {A = A ⊕ B} (sel₂ x) (case y z)
    = cut x z
  cut {Γ} {Δ} {A = A & B} (case x y) (sel₁ z)
    = cut x z
  cut {Γ} {Δ} {A = A & B} (case x y) (sel₂ z)
    = cut y z
  cut {Γ} {Δ} {A = ![ n ] A} x y
    = interleaveIn (here P.refl) x (expand y)
  cut {Γ} {Δ} {A = ?[ n ] A} x y
    = exch (swp₂ Γ)
    $ interleaveIn {_ ∷ Δ} {Γ} (here P.refl) y
    $ P.subst (λ A → ⊢ⁿᶠ replicate⁺ n A ++ Γ) (P.sym $ ^-inv A)
    $ expand x
  cut {Γ} {Δ} {A} (exch b x) y
    = exch (B.++-cong {ys₁ = Δ} (del-from b (here P.refl)) I.id)
    $ cutIn (from b ⟨$⟩ here P.refl) (here P.refl) x y
  cut {Γ} {Δ} {A} x (exch b y)
    = exch (B.++-cong {xs₁ = Γ} I.id (del-from b (here P.refl)))
    $ cutIn (here P.refl) (from b ⟨$⟩ here P.refl) x y


  cutIn : {Γ Δ : Environment} {A : Type} (i : A ∈ Γ) (j : A ^ ∈ Δ) →

    ⊢ⁿᶠ Γ → ⊢ⁿᶠ Δ →
    ----------------
    ⊢ⁿᶠ Γ - i ++ Δ - j

  cutIn (here P.refl) (here P.refl) x y = cut x y

  cutIn {_} {Θ} (there i) j (send {Γ} {Δ} x y) z
    with split Γ i
  ... | inj₁ (k , p) rewrite p
      = P.subst ⊢ⁿᶠ_ (P.sym (++.assoc (_ ∷ Γ - k) Δ (Θ - j)))
      $ exch (swp₃ (_ ∷ Γ - k) Δ)
      $ P.subst ⊢ⁿᶠ_ (++.assoc (_ ∷ Γ - k) (Θ - j) Δ)
      $ flip send y
      $ cutIn (there k) j x z
  ... | inj₂ (k , p) rewrite p
      = P.subst ⊢ⁿᶠ_ (P.sym (++.assoc (_ ∷ Γ) (Δ - k) (Θ - j)))
      $ send x
      $ cutIn (there k) j y z
  cutIn (there i) j (recv x) y
    = recv
    $ cutIn (there (there i)) j x y
  cutIn (there i) j (sel₁ x) y
    = sel₁
    $ cutIn (there i) j x y
  cutIn (there i) j (sel₂ x) y
    = sel₂
    $ cutIn (there i) j x y
  cutIn (there i) j (case x y) z
    = case
    ( cutIn (there i) j x z )
    ( cutIn (there i) j y z )
  cutIn (there ()) j halt y
  cutIn (there i) j (wait x) y
    = wait
    $ cutIn i j x y
  cutIn (there i) j loop y
    = loop
  cutIn {Γ} {Δ} (there i) j (mk?₁ x) y
    = mk?₁
    $ cutIn (there i) j x y
  cutIn {Γ} {Δ} (there i) j (mk!₁ x) y
    = mk!₁
    $ cutIn (there i) j x y
  cutIn {Γ} {Δ} (there i) j (cont x) y
    = cont
    $ cutIn (there (there i)) j x y
  cutIn {_} {Θ} (there i) j (pool {Γ} {Δ} x y) z
    with split Γ i
  ... | inj₁ (k , p) rewrite p
      = P.subst ⊢ⁿᶠ_ (P.sym (++.assoc (_ ∷ Γ - k) Δ (Θ - j)))
      $ exch (swp₃ (_ ∷ Γ - k) Δ)
      $ P.subst ⊢ⁿᶠ_ (++.assoc (_ ∷ Γ - k) (Θ - j) Δ)
      $ flip pool y
      $ cutIn (there k) j x z
  ... | inj₂ (k , p) rewrite p
      = P.subst ⊢ⁿᶠ_ (P.sym (++.assoc (_ ∷ Γ) (Δ - k) (Θ - j)))
      $ pool x
      $ cutIn (there k) j y z

  cutIn {Θ} {_} i (there j) x (send {Γ} {Δ} y z)
    with split Γ j
  ... | inj₁ (k , p) rewrite p
      = exch (bwd [] (Θ - i))
      $ P.subst ⊢ⁿᶠ_ (++.assoc (_ ∷ Θ - i) (Γ - k) Δ)
      $ flip send z
      $ exch (fwd [] (Θ - i))
      $ cutIn i (there k) x y
  ... | inj₂ (k , p) rewrite p
      = exch (swp [] (Θ - i) (_ ∷ Γ))
      $ send y
      $ exch (fwd [] (Θ - i))
      $ cutIn i (there k) x z
  cutIn {Γ} i (there j) x (recv {Δ} y)
    = exch (bwd [] (Γ - i))
    $ recv
    $ exch (swp [] (_ ∷ _ ∷ []) (Γ - i))
    $ cutIn i (there (there j)) x y
  cutIn {Γ} {Δ} i (there j) x (sel₁ y)
    = exch (bwd [] (Γ - i))
    $ sel₁
    $ exch (fwd [] (Γ - i))
    $ cutIn i (there j) x y
  cutIn {Γ} {Δ} i (there j) x (sel₂ y)
    = exch (bwd [] (Γ - i))
    $ sel₂
    $ exch (fwd [] (Γ - i))
    $ cutIn i (there j) x y
  cutIn {Γ} {Δ} i (there j) x (case y z)
    = exch (bwd [] (Γ - i))
    $ case
    ( exch (fwd [] (Γ - i)) $ cutIn i (there j) x y )
    ( exch (fwd [] (Γ - i)) $ cutIn i (there j) x z )
  cutIn {Γ} i (there ()) x halt
  cutIn {Γ} {Δ} i (there j) x (wait y)
    = exch (bwd [] (Γ - i))
    $ wait
    $ cutIn i j x y
  cutIn {Γ} {Δ} i (there j) x loop
    = exch (bwd [] (Γ - i)) loop
  cutIn {Γ} {Δ} i (there j) x (mk?₁ y)
    = exch (bwd [] (Γ - i))
    $ mk?₁
    $ exch (fwd [] (Γ - i))
    $ cutIn i (there j) x y
  cutIn {Γ} {Δ} i (there j) x (mk!₁ y)
    = exch (bwd [] (Γ - i))
    $ mk!₁
    $ exch (fwd [] (Γ - i))
    $ cutIn i (there j) x y
  cutIn {Γ} {Δ} i (there j) x (cont y)
    = exch (bwd [] (Γ - i))
    $ cont
    $ exch (swp [] (_ ∷ _ ∷ []) (Γ - i))
    $ cutIn i (there (there j)) x y
  cutIn {Θ} {_} i (there j) x (pool {Γ} {Δ} y z)
    with split Γ j
  ... | inj₁ (k , p) rewrite p
      = exch (bwd [] (Θ - i))
      $ P.subst ⊢ⁿᶠ_ (++.assoc (_ ∷ Θ - i) (Γ - k) Δ)
      $ flip pool z
      $ exch (fwd [] (Θ - i))
      $ cutIn i (there k) x y
  ... | inj₂ (k , p) rewrite p
      = exch (swp [] (Θ - i) (_ ∷ Γ))
      $ pool y
      $ exch (fwd [] (Θ - i))
      $ cutIn i (there k) x z

  cutIn {Γ} {Δ} i j (exch b x) y
    = exch (B.++-cong {ys₁ = Δ - j} (del-from b i ) I.id)
    $ cutIn (from b ⟨$⟩ i) j x y
  cutIn {Γ} {Δ} i j x (exch b y)
    = exch (B.++-cong {xs₁ = Γ - i} I.id (del-from b j))
    $ cutIn i (from b ⟨$⟩ j) x y

  interleaveIn : {Γ Δ : Environment} {A : Type} {n : ℕ⁺} (i : ![ n ] A ∈ Γ) →

    ⊢ⁿᶠ Γ → ⊢ⁿᶠ replicate⁺ n (A ^) ++ Δ →
    -----------------------------------------------
    ⊢ⁿᶠ Γ - i ++ Δ

  interleaveIn (here P.refl) (mk!₁ {Γ} x) z
    = cut x z
  interleaveIn {._} {Θ} (here P.refl) (pool {Γ} {Δ} {A} {m} {n} x y) z
    = P.subst ⊢ⁿᶠ_ (P.sym $ ++.assoc Γ Δ Θ)
    $ interleaveIn (here P.refl) x
    $ exch (swp [] (replicate⁺ m _) Δ)
    $ interleaveIn (here P.refl) y
    $ exch (swp [] (replicate⁺ n _) (replicate⁺ m _))
    $ P.subst ⊢ⁿᶠ_ (++.assoc (replicate⁺ m _) (replicate⁺ n _) Θ)
    $ P.subst (λ Γ → ⊢ⁿᶠ Γ ++ Θ) (P.sym $ replicate⁺-++-commute m n) z
  interleaveIn {._} {Θ} (there i) (send {Γ} {Δ} {A} {B} x y) z
    with split Γ i
  ... | inj₁ (j , p) rewrite p
    = P.subst ⊢ⁿᶠ_ (P.sym $ ++.assoc (_ ∷ Γ - j) Δ Θ)
    $ exch (swp₃ (_ ∷ Γ - j) Δ {Θ})
    $ P.subst ⊢ⁿᶠ_ (++.assoc (_ ∷ Γ - j) Θ Δ)
    $ flip send y
    $ interleaveIn (there j) x z
  ... | inj₂ (j , p) rewrite p
    = P.subst ⊢ⁿᶠ_ (P.sym $ ++.assoc (_ ∷ Γ) (Δ - j) Θ)
    $ send x
    $ interleaveIn (there j) y z
  interleaveIn (there i) (recv x)   z
    = recv
    $ interleaveIn (there (there i)) x z
  interleaveIn (there i) (sel₁ x)   z
    = sel₁
    $ interleaveIn (there i) x z
  interleaveIn (there i) (sel₂ x)   z
    = sel₂
    $ interleaveIn (there i) x z
  interleaveIn (there i) (case x y) z
    = case (interleaveIn (there i) x z) (interleaveIn (there i) y z)
  interleaveIn (there ()) halt z
  interleaveIn (there i) (wait x)   z
    = wait
    $ interleaveIn i x z
  interleaveIn (there i)  loop      z
    = loop
  interleaveIn (there i) (mk?₁ x)   z
    = mk?₁
    $ interleaveIn (there i) x z
  interleaveIn (there i) (mk!₁ x)   z
    = mk!₁
    $ interleaveIn (there i) x z
  interleaveIn (there i) (cont x)   z
    = cont
    $ interleaveIn (there (there i)) x z
  interleaveIn {._} {Θ} (there i) (pool {Γ} {Δ} x y) z
    with split Γ i
  ... | inj₁ (j , p) rewrite p
    = P.subst ⊢ⁿᶠ_ (P.sym $ ++.assoc (_ ∷ Γ - j) Δ Θ)
    $ exch (swp₃ (_ ∷ Γ - j) Δ {Θ})
    $ P.subst ⊢ⁿᶠ_ (++.assoc (_ ∷ Γ - j) Θ Δ)
    $ flip pool y
    $ interleaveIn (there j) x z
  ... | inj₂ (j , p) rewrite p
    = P.subst ⊢ⁿᶠ_ (P.sym $ ++.assoc (_ ∷ Γ) (Δ - j) Θ)
    $ pool x
    $ interleaveIn (there j) y z
  interleaveIn {Γ} {Δ} i (exch b x) z
    = exch (B.++-cong {ys₁ = Δ} (del-from b i) I.id)
    $ interleaveIn (from b ⟨$⟩ i) x z

-- -}
-- -}
-- -}
-- -}
-- -}
