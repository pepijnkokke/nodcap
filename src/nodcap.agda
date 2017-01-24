open import Level renaming (suc to lsuc; zero to lzero)
open import Algebra
open import Data.Nat as ℕ                   using (ℕ)
open import Data.Pos as ℤ⁺
open import Data.List as L                  using (List; _∷_; []; _++_)
open import Data.List.Properties as LP      using ()
open import Data.List.Properties.Ext as LPE using ()
open import Data.List.Any as LA             using (Any; here; there)
open import Data.List.Any.BagAndSetEquality as B
open import Data.Product as PR              using (∃; _×_; _,_; proj₁; proj₂)
open import Data.Vec as V                   using (Vec; _∷_; [])
open import Data.Vec.Properties as VP       using ()
open import Data.Sum                        using (_⊎_; inj₁; inj₂)
open import Function                        using (_∘_; _$_; flip)
open import Function.Equality               using (_⟨$⟩_)
open import Function.Inverse as I           using (module Inverse)
open        Inverse                         using (to; from)
open import Logic.Context
open import Logic.Environment
open import Relation.Binary.PropositionalEquality as P using (_≡_)
open P.≡-Reasoning

module nodcap (Atom : Set) where

private
  module ++ {a} {A : Set a} = Monoid (L.monoid A)


-- Types.

data Type : Set where
  𝟏 : Type
  ⊥ : Type
  𝟎 : Type
  ⊤ : Type
  _⊗_ : (A B : Type) → Type
  _⅋_ : (A B : Type) → Type
  _⊕_ : (A B : Type) → Type
  _&_ : (A B : Type) → Type
  ⊗[_^_] : (A : Type) (n : ℤ⁺) → Type
  ⅋[_^_] : (A : Type) (n : ℤ⁺) → Type


-- Duality.

_^ : Type → Type
𝟏 ^ = ⊥
⊥ ^ = 𝟏
𝟎 ^ = ⊤
⊤ ^ = 𝟎
(A ⊗ B) ^ = (A ^) ⅋ (B ^)
(A ⅋ B) ^ = (A ^) ⊗ (B ^)
(A ⊕ B) ^ = (A ^) & (B ^)
(A & B) ^ = (A ^) ⊕ (B ^)
⊗[ A ^ n ] ^ = ⅋[ A ^ ^ n ]
⅋[ A ^ n ] ^ = ⊗[ A ^ ^ n ]

^-inv : ∀ A →  A ^ ^ ≡ A
^-inv 𝟏 = P.refl
^-inv ⊥ = P.refl
^-inv 𝟎 = P.refl
^-inv ⊤ = P.refl
^-inv (A ⊗ B) = P.cong₂ _⊗_ (^-inv A) (^-inv B)
^-inv (A ⅋ B) = P.cong₂ _⅋_ (^-inv A) (^-inv B)
^-inv (A ⊕ B) = P.cong₂ _⊕_ (^-inv A) (^-inv B)
^-inv (A & B) = P.cong₂ _&_ (^-inv A) (^-inv B)
^-inv ⊗[ A ^ n ] = P.cong ⊗[_^ n ] (^-inv A)
^-inv ⅋[ A ^ n ] = P.cong ⅋[_^ n ] (^-inv A)


-- Polarities.

data Pos : Type → Set where
  𝟏 : Pos 𝟏
  𝟎 : Pos 𝟎
  _⊗_ : (A B : Type) → Pos (A ⊗ B)
  _⊕_ : (A B : Type) → Pos (A ⊕ B)
  ⊗[_^_] : (A : Type) (n : ℤ⁺) → Pos ⊗[ A ^ n ]

data Neg : Type → Set where
  ⊥ : Neg ⊥
  ⊤ : Neg ⊤
  _⅋_ : (A B : Type) → Neg (A ⅋ B)
  _&_ : (A B : Type) → Neg (A & B)
  ⅋[_^_] : (A : Type) (n : ℤ⁺) → Neg ⅋[ A ^ n ]

pol? : (A : Type) → Pos A ⊎ Neg A
pol? 𝟏 = inj₁ 𝟏
pol? ⊥ = inj₂ ⊥
pol? 𝟎 = inj₁ 𝟎
pol? ⊤ = inj₂ ⊤
pol? (A ⊗ B) = inj₁ (A ⊗ B)
pol? (A ⅋ B) = inj₂ (A ⅋ B)
pol? (A ⊕ B) = inj₁ (A ⊕ B)
pol? (A & B) = inj₂ (A & B)
pol? ⊗[ A ^ n ] = inj₁ ⊗[ A ^ n ]
pol? ⅋[ A ^ n ] = inj₂ ⅋[ A ^ n ]

^-posney : {A : Type} (P : Pos A) → Neg (A ^)
^-posney 𝟏 = ⊥
^-posney 𝟎 = ⊤
^-posney (A ⊗ B) = (A ^) ⅋ (B ^)
^-posney (A ⊕ B) = (A ^) & (B ^)
^-posney ⊗[ A ^ n ] = ⅋[ A ^ ^ n ]

^-negpos : {A : Type} (N : Neg A) → Pos (A ^)
^-negpos ⊥ = 𝟏
^-negpos ⊤ = 𝟎
^-negpos (A ⅋ B) = (A ^) ⊗ (B ^)
^-negpos (A & B) = (A ^) ⊕ (B ^)
^-negpos ⅋[ A ^ n ] = ⊗[ A ^ ^ n ]


-- Contexts.

Context : Set
Context = List Type

open LA.Membership-≡


-- Typing Rules.

infix 1 ⊢_

data ⊢_ : Context → Set where

  send : {Γ Δ : Context} {A B : Type} →

       ⊢ A ∷ Γ → ⊢ B ∷ Δ →
       -------------------
       ⊢ A ⊗ B ∷ Γ ++ Δ

  recv : {Γ : Context} {A B : Type} →

       ⊢ A ∷ B ∷ Γ →
       -------------
       ⊢ A ⅋ B ∷ Γ

  sel₁ : {Γ : Context} {A B : Type} →

       ⊢ A ∷ Γ →
       -----------
       ⊢ A ⊕ B ∷ Γ

  sel₂ : {Γ : Context} {A B : Type} →

       ⊢ B ∷ Γ →
       -----------
       ⊢ A ⊕ B ∷ Γ

  case : {Γ : Context} {A B : Type} →

       ⊢ A ∷ Γ → ⊢ B ∷ Γ →
       -------------------
       ⊢ A & B ∷ Γ

  halt :

       --------
       ⊢ 𝟏 ∷ []

  wait : {Γ : Context} →

       ⊢ Γ →
       -------
       ⊢ ⊥ ∷ Γ

  loop : {Γ : Context} →

       -------
       ⊢ ⊤ ∷ Γ

  exch : {Γ Δ : Context} →

       Γ ∼[ bag ] Δ → ⊢ Γ →
       --------------------
       ⊢ Δ


  cont : {Γ : Context} {A : Type} {m n : ℤ⁺} →

       ⊢ ⅋[ A ^ m ] ∷ ⅋[ A ^ n ] ∷ Γ →
       ------------------------------
       ⊢ ⅋[ A ^ m + n ] ∷ Γ

  pool : {Γ Δ : Context} {A : Type} {m n : ℤ⁺} →

       ⊢ ⊗[ A ^ m ] ∷ Γ → ⊢ ⊗[ A ^ n ] ∷ Δ →
       -------------------------------------
       ⊢ ⊗[ A ^ m + n ] ∷ Γ ++ Δ

  mk⅋₁ : {Γ : Context} {A : Type} →

       ⊢ A ∷ Γ →
       ----------------
       ⊢ ⅋[ A ^ one ] ∷ Γ

  mk⊗₁ : {Γ : Context} {A : Type} →

       ⊢ A ∷ Γ →
       ----------------
       ⊢ ⊗[ A ^ one ] ∷ Γ


mutual
  {-# TERMINATING #-} -- by decreasing parameter `n`
  expand : {Γ : Context} {A : Type} {n : ℤ⁺} →

           ⊢ ⅋[ A ^ n ] ∷ Γ →
           --------------------
           ⊢ ℤ⁺.replicate n A ++ Γ

  expand {Γ} {A} {n} (exch b x)
    = exch (B.++-cong {xs₁ = replicate n A} I.id (del-from b (here P.refl)))
    $ expandIn (from b ⟨$⟩ here P.refl) x
  expand {Γ} {A} {.(m + n)} (cont {.Γ} {.A} {m} {n} x)
    rewrite P.sym (replicate-++ m n {A})
          | ++.assoc (replicate m A) (replicate n A) Γ
          = exch (swp [] (replicate m A) (replicate n A))
          $ expand {n = n}
          $ exch (swp [] (_ ∷ []) (replicate m A))
          $ expand {n = m} x
  expand {Γ} {A} {_} (mk⅋₁ x)
    = x

  -- by decreasiny parameter `A`
  expandIn : {Γ : Context} {A : Type} {n : ℤ⁺} →
             (i : ⅋[ A ^ n ] ∈ Γ) →

             ⊢ Γ →
             ----------------------------
             ⊢ replicate n A ++ Γ - i

  expandIn (here P.refl) x = expand x
  expandIn {_} {A} {n} (there i) (send {Γ} {Δ} x h)
    with split Γ i
  ... | inj₁ (j , p) rewrite p
      = exch (swp [] (replicate n A) (_ ∷ []) I.∘
              I.sym (ass (_ ∷ replicate n A) (Γ - j )))
      $ flip send h
      $ exch (swp [] (_ ∷ []) (replicate n A))
      $ expandIn (there j) x
  ... | inj₂ (j , p) rewrite p
      = exch (swp [] (replicate n A) (_ ∷ Γ))
      $ send x
      $ exch (swp [] (_ ∷ []) (replicate n A))
      $ expandIn (there j) h
  expandIn {Γ} {A} {n} (there i) (recv x)
    = exch (swp [] (replicate n A) (_ ∷ []))
    $ recv
    $ exch (swp [] (_ ∷ _ ∷ []) (replicate n A))
    $ expandIn (there (there i)) x
  expandIn {Γ} {A} {n} (there i) (sel₁ x)
    = exch (swp [] (replicate n A) (_ ∷ []))
    $ sel₁
    $ exch (swp [] (_ ∷ []) (replicate n A))
    $ expandIn (there i) x
  expandIn {Γ} {A} {n} (there i) (sel₂ x)
    = exch (swp [] (replicate n A) (_ ∷ []))
    $ sel₂
    $ exch (swp [] (_ ∷ []) (replicate n A))
    $ expandIn (there i) x
  expandIn {Γ} {A} {n} (there i) (case x h)
    = exch (swp [] (replicate n A) (_ ∷ []))
    $ case
      ( exch (swp [] (_ ∷ []) (replicate n A))
      $ expandIn (there i) x )
      ( exch (swp [] (_ ∷ []) (replicate n A))
      $ expandIn (there i) h )
  expandIn (there ()) halt
  expandIn {Γ} {A} {n} (there i) (wait x)
    = exch (swp [] (replicate n A) (_ ∷ []))
    $ wait
    $ expandIn i x
  expandIn {Γ} {A} {n} (there i)  loop
    = exch (swp [] (replicate n A) (_ ∷ []))
    $ loop
  expandIn {Γ} {A} {n} (there i) (cont x)
    = exch (swp [] (replicate n A) (_ ∷ []))
    $ cont
    $ exch (swp [] (_ ∷ _ ∷ []) (replicate n A))
    $ expandIn (there (there i)) x
  expandIn {_} {A} {n} (there i) (pool {Γ} {Δ} x h)
    with split Γ i
  ... | inj₁ (j , p) rewrite p
      = exch (swp [] (replicate n A) (_ ∷ []) I.∘
              I.sym (ass (_ ∷ replicate n A) (Γ - j)))
      $ flip pool h
      $ exch (swp [] (_ ∷ []) (replicate n A))
      $ expandIn (there j) x
  ... | inj₂ (j , p) rewrite p
      = exch (swp [] (replicate n A) (_ ∷ Γ))
      $ pool x
      $ exch (swp [] (_ ∷ []) (replicate n A))
      $ expandIn (there j) h
  expandIn {Γ} {A} {n} (there i) (mk⅋₁ x)
    = exch (swp [] (replicate n A) (_ ∷ []))
    $ mk⅋₁
    $ exch (swp [] (_ ∷ []) (replicate n A))
    $ expandIn (there i) x
  expandIn {Γ} {A} {n} (there i) (mk⊗₁ x)
    = exch (swp [] (replicate n A) (_ ∷ []))
    $ mk⊗₁
    $ exch (swp [] (_ ∷ []) (replicate n A))
    $ expandIn (there i) x
  expandIn {Γ} {A} {n} i (exch b x)
    = exch (B.++-cong {xs₁ = replicate n A} I.id (del-from b i))
    $ expandIn (from b ⟨$⟩ i) x


-- a series of identical sequents constructed from the Γmn in an Unpool instance
[⊢_,_]m : {n : ℕ} {mkS : Context → Set} →
          List (Vec (∃ λ Γij → mkS Γij) n) → Context → Set
[⊢ Γmn , Δ ]m = Env (L.map (λ Γin → ⊢ L.concat (L.map proj₁ (V.toList Γin)) ++ Δ) Γmn)


record Unpool (n : ℤ⁺) (Γ : Context) (mkS : Context → Set) : Set where

  constructor UP[_,_]

  field
    Γmn : List (Vec (∃ λ Γij → mkS Γij) (toℕ n))
    ΣnΓnmΔ→ΓΔ : {Δ : Context} →

      [⊢ Γmn , Δ ]m →
      ---------------
      ⊢ Γ ++ Δ

infix 1 Unpool

syntax Unpool n Γ (λ Γᵢ → S) = Σ[i≤ n ]∃[ Γᵢ ⊆ Γ ] S

mutual
  unpool : {Γ : Context} {A : Type} {n : ℤ⁺} →

    ⊢ ⊗[ A ^ n ] ∷ Γ →
    -----------------------------
    Σ[i≤ n ]∃[ Γᵢ ⊆ Γ ] ⊢ A ∷ Γᵢ

  unpool (exch b x) = {!!}
  unpool (pool x y) = {!!}
  unpool (mk⊗₁ {Γ} {A} x) = UP[ Γ' , f' ]
    where
      Γ' : List (Vec (∃ (λ Γᵢ → ⊢ A ∷ Γᵢ)) 1)
      Γ' = L.[ V.[ Γ , x ] ]
      f' : {Δ : Context} → [⊢ Γ' , Δ ]m → ⊢ Γ ++ Δ
      f' (x ∷ []) = P.subst ⊢_ (P.cong (_++ _) (proj₂ ++.identity Γ)) x

  unpoolIn : {Γ : Context} {A : Type} {n : ℤ⁺} →
             (i : ⊗[ A ^ n ] ∈ Γ) →

    ⊢ Γ →
    -----------------------------
    Σ[i≤ n ]∃[ Γᵢ ⊆ Γ - i ] ⊢ A ∷ Γᵢ

  unpoolIn (here P.refl) x = unpool x
  unpoolIn (there i) (send x y) = {!!}
  unpoolIn (there i) (recv x)   = {!!}
  unpoolIn (there i) (sel₁ x)   = {!!}
  unpoolIn (there i) (sel₂ x)   = {!!}
  unpoolIn (there i) (case {Γ} {A} {B} x y)

    with unpoolIn (there i) x | unpoolIn (there i) y
  ... | UP[ Γx , fx ] | UP[ Γy , fy ] = UP[ Γx ++ Γy , {!!} ]
    where
      f' : {Δ : Context} →

           [⊢ Γx ++ Γy , Δ ]m →
           --------------------
           ⊢ A & B ∷ Γ - i ++ Δ

      f' {Δ} zs = case (fx (proj₁ xs×ys)) (fy (proj₂ xs×ys))
        where
          xs×ys : [⊢ Γx , Δ ]m × [⊢ Γy , Δ ]m
          xs×ys = splitEnv (P.subst Env (LP.map-++-commute _ Γx Γy) zs)

  unpoolIn (there i)  halt      = {!!}
  unpoolIn (there i) (wait x)   = {!!}
  unpoolIn (there i)  loop      = {!!}
  unpoolIn (there i) (exch e y) = {!!}
  unpoolIn (there i) (cont x)   = {!!}
  unpoolIn (there i) (pool x y) = {!!}
  unpoolIn (there i) (mk⅋₁ x)   = {!!}
  unpoolIn (there i) (mk⊗₁ x)   = {!!}







{-
infixr 1 Unpool

record Unpool (n : ℤ⁺) (Γ : Context) (S< : Context → Set) : Set where
  constructor
    UP[_,_,_]
  field
    cs : List (∃ (λ Γᵢ → S< Γᵢ))
    |cs|=n : L.length cs ≡ toℕ n

  ΣᵢΓᵢ : Context
  ΣᵢΓᵢ = L.concat (L.map proj₁ cs)

  field
    ΣᵢΓᵢ→Γ : {Δ : Context} →

           ⊢ ΣᵢΓᵢ ++ Δ →
           ----------
           ⊢ Γ ++ Δ

syntax Unpool n Γ (λ Γᵢ → S) = Σ[i≤ n ]∃[ Γᵢ ⊆ Γ ] S

{-
mutual
  unpool : {Γ : Context} {A : Type} {n : ℤ⁺} →

           ⊢ ⊗[ A ^ n ] ∷ Γ →
           -----------------------------
           Σ[i≤ n ]∃[ Γᵢ ⊆ Γ ] ⊢ A ∷ Γᵢ

  unpool (exch b x)
    = {!!} -- compose `exch` with `ΣᵢΓᵢ→Γ`
    $ unpoolIn (b ⟨⇐⟩ here P.refl) x
  unpool (pool {Γ} {Δ} {A} {m} {n} x y)
    with unpool x | unpool y
  ... | UP[ c₁ , l₁ , f₁ ] | UP[ c₂ , l₂ , f₂ ] = UP[  c' ,  l' ,  f' ]
    where
      c' = c₁ ++ c₂
      l' = P.trans (LP.length-++ c₁) (P.trans (P.cong₂ ℕ._+_ l₁ l₂) (toℕ-+ m))
      f' : {Θ : Context} → ⊢ L.concat (L.map proj₁ (c₁ ++ c₂)) ++ Θ → ⊢ (Γ ++ Δ) ++ Θ
      f' = P.subst ⊢_ (P.sym (++.assoc Γ Δ _))
         ∘ exch (swp [] Γ Δ)
         ∘ f₂
         ∘ exch (swp [] (L.concat (L.map proj₁ c₂)) Γ)
         ∘ f₁
         ∘ P.subst ⊢_ (++.assoc (L.concat (L.map proj₁ c₁)) (L.concat (L.map proj₁ c₂)) _)
         ∘ P.subst (λ Γ → ⊢ Γ ++ _) (P.sym (concat-++-commute (L.map proj₁ c₁) (L.map proj₁ c₂)))
         ∘ P.subst (λ Γ → ⊢ L.concat Γ ++ _) (LP.map-++-commute proj₁ c₁ c₂)

  unpool (mk⊗₁ {Γ} x) = UP[ c' , l' , f' ]
    where
      c' = L.[ Γ , x ]
      l' = P.refl
      f' : {Δ : Context} → ⊢ (Γ ++ []) ++ Δ → ⊢ Γ ++ Δ
      f' = P.subst ⊢_ (P.cong (_++ _) (proj₂ ++.identity Γ))

  unpoolIn : {Γ : Context} {A : Type} {n : ℤ⁺} →
             (i : ⊗[ A ^ n ] ∈ Γ) →

           ⊢ Γ →
           -----------------------------
           Σ[i≤ n ]∃[ Γᵢ ⊆ Γ - i ] ⊢ A ∷ Γᵢ

  unpoolIn (here P.refl) x = unpool x
  unpoolIn (there i) (send {Γ} {Δ} {A} {B} x y) with split Γ i
  unpoolIn (there i) (send {Γ} {Δ} {A} {B} x y) | inj₁ (j , p) rewrite p
    with unpoolIn (there j) x
  ... | UP[ c , l , f ] = UP[ c , l , f' ]
    where
      f' : {Θ : Context} → ⊢ L.concat (L.map proj₁ c) ++ Θ → ⊢ A ⊗ B ∷ ((Γ - j) ++ Δ) ++ Θ
      f' = P.subst ⊢_ (P.sym (++.assoc (A ⊗ B ∷ Γ - j) Δ _))
         ∘ exch (swp' (A ⊗ B ∷ Γ - j) Δ)
         ∘ P.subst ⊢_ (++.assoc (A ⊗ B ∷ Γ - j) _ Δ)
         ∘ flip send y
         ∘ f
  unpoolIn (there i) (send {Γ} {Δ} {A} {B} x y) | inj₂ (j , p) rewrite p
    with unpoolIn (there j) y
  ... | UP[ c , l , f ] = UP[ c , l , f' ]
    where
      f' : {Θ : Context} → ⊢ L.concat (L.map proj₁ c) ++ Θ → ⊢ A ⊗ B ∷ (Γ ++ (Δ - j)) ++ Θ
      f' = P.subst ⊢_ (P.sym (++.assoc (A ⊗ B ∷ Γ) (Δ - j) _))
         ∘ send x
         ∘ f
  unpoolIn (there i) (recv {Γ} {A} {B} x)
    with unpoolIn (there (there i)) x
  ... | UP[ c , l , f ] = UP[ c , l , recv ∘ f ]
  unpoolIn (there i) (sel₁ x)
    with unpoolIn (there i) x
  ... | UP[ c , l , f ] = UP[ c , l , sel₁ ∘ f ]
  unpoolIn (there i) (sel₂ x)
    with unpoolIn (there i) x
  ... | UP[ c , l , f ] = UP[ c , l , sel₂ ∘ f ]
  unpoolIn (there i) (case x y)
    with unpoolIn (there i) x | unpoolIn (there i) y
  ... | UP[ c₁ , l₁ , f₁ ] | UP[ c₂ , l₂ , f₂ ] = {!!}
  unpoolIn (there i)  halt      = {!!}
  unpoolIn (there i) (wait x)   = {!!}
  unpoolIn (there i)  loop      = {!!}
  unpoolIn (there i) (exch b x) = {!!}
  unpoolIn (there i) (cont x)   = {!!}
  unpoolIn (there i) (pool x y) = {!!}
  unpoolIn (there i) (mk⅋₁ x)   = {!!}
  unpoolIn (there i) (mk⊗₁ x)   = {!!}


-- -}
-- -}
-- -}
-- -}
-- -}
