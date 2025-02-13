-- This file contains the instantiation of our framework for System F
-- from paper (code displayed without boxes).

module Simple.SystemF where

open import Data.List using (List; []; _∷_)
open import Data.Product using (_,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; cong; cong₂; subst; module ≡-Reasoning)
open ≡-Reasoning

open import Simple.Kits

-- Operators -------------------------------------------------------------------

infix   3  _⊢_  _↪_  _⊢_∶_
infixr  5  λx_  Λα_  ∀[α∶_]_
infixr  6  _⇒_
infixl  6  _·_  _∙_
infix   7  `_

-- Sorts -----------------------------------------------------------------------

data Sort : SortTy → Set where -- Our syntax supports:
  𝕖  : Sort Var    -- expressions and expression variables;
  𝕥  : Sort Var    -- types and type variables; and
  𝕜  : Sort NoVar  -- kinds, but no kind variables.

-- Syntax ----------------------------------------------------------------------

private variable
  st                         : SortTy
  s s₁ s₂ s₃ s' s₁' s₂' s₃'  : Sort st
  S S₁ S₂ S₃ S' S₁' S₂' S₃'  : List (Sort Var)
  x y z x₁ x₂                : S ∋ s

data _⊢_ : List (Sort Var) → Sort st → Set where
  `_        : S ∋ s → S ⊢ s                -- Expression and type variables
  λx_       : (𝕖 ∷ S) ⊢ 𝕖 → S ⊢ 𝕖          -- Expression abstraction
  Λα_       : (𝕥 ∷ S) ⊢ 𝕖 → S ⊢ 𝕖          -- Type abstraction
  ∀[α∶_]_   : S ⊢ 𝕜 → (𝕥 ∷ S) ⊢ 𝕥 → S ⊢ 𝕥  -- Universal quantification
  _·_       : S ⊢ 𝕖 → S ⊢ 𝕖 → S ⊢ 𝕖        -- Expression application
  _∙_       : S ⊢ 𝕖 → S ⊢ 𝕥 → S ⊢ 𝕖        -- Type application
  _⇒_       : S ⊢ 𝕥 → S ⊢ 𝕥 → S ⊢ 𝕥        -- Function type
  ★         : S ⊢ 𝕜                        -- Type kind

private variable
  e e₁ e₂ e₃ e' e₁' e₂'  : S ⊢ 𝕖
  t t₁ t₂ t₃ t' t₁' t₂'  : S ⊢ 𝕥
  k k₁ k₂ k₃ k' k₁' k₂'  : S ⊢ 𝕜

-- Substitution & Lemmas -------------------------------------------------------

-- IMPORTANT: Everything in this section is derived automatically in
-- our full framework.

SystemF-Syntax : Syntax
SystemF-Syntax = record { Sort = Sort ; _⊢_  = _⊢_ ; `_ = `_ ; `-injective  = λ { refl → refl } }

open Syntax SystemF-Syntax hiding (Sort; _⊢_; `_)

_⋯_ : ∀ ⦃ K : Kit _∋/⊢_ ⦄ → S₁ ⊢ s → S₁ –[ K ]→ S₂ → S₂ ⊢ s
(` x)           ⋯ ϕ = `/id (x & ϕ)
(λx t)          ⋯ ϕ = λx (t ⋯ (ϕ ↑ 𝕖))
(Λα t)          ⋯ ϕ = Λα (t ⋯ (ϕ ↑ 𝕥))
(∀[α∶ t₁ ] t₂)  ⋯ ϕ = ∀[α∶ t₁ ⋯ ϕ ] (t₂ ⋯ (ϕ ↑ 𝕥))
(t₁ · t₂)       ⋯ ϕ = (t₁ ⋯ ϕ) · (t₂ ⋯ ϕ)
(t₁ ∙ t₂)       ⋯ ϕ = (t₁ ⋯ ϕ) ∙ (t₂ ⋯ ϕ)
(t₁ ⇒ t₂)       ⋯ ϕ = (t₁ ⋯ ϕ) ⇒ (t₂ ⋯ ϕ)
★               ⋯ ϕ = ★

⋯-id : ∀ ⦃ K : Kit _∋/⊢_ ⦄ (t : S ⊢ s) → t ⋯ id ≡ t
⋯-id (` x)   =  `/`-is-` x
⋯-id (λx t)  =  λx (t ⋯ (id ↑ 𝕖))  ≡⟨ cong (λ ϕ → λx (t ⋯ ϕ)) (~-ext id↑~id) ⟩
                λx (t ⋯ id)        ≡⟨ cong (λ t → λx t) (⋯-id t) ⟩
                λx t               ∎
⋯-id (t₁ · t₂)       = cong₂ _·_ (⋯-id t₁) (⋯-id t₂)
⋯-id (Λα t)          = cong Λα_ (
  t ⋯ (id ↑ 𝕥)  ≡⟨ cong (t ⋯_) (~-ext id↑~id) ⟩
  t ⋯ id        ≡⟨ ⋯-id t ⟩
  t             ∎)
⋯-id (∀[α∶ t₁ ] t₂)  = cong₂ ∀[α∶_]_ (⋯-id t₁) (
  t₂ ⋯ (id ↑ 𝕥)  ≡⟨ cong (t₂ ⋯_) (~-ext id↑~id) ⟩
  t₂ ⋯ id        ≡⟨ ⋯-id t₂ ⟩
  t₂             ∎)
⋯-id (t₁ ∙ t₂)       = cong₂ _∙_ (⋯-id t₁) (⋯-id t₂)
⋯-id (t₁ ⇒ t₂)       = cong₂ _⇒_ (⋯-id t₁) (⋯-id t₂)
⋯-id ★               = refl

SystemF-Traversal : Traversal
SystemF-Traversal = record { _⋯_ = _⋯_ ; ⋯-id = ⋯-id ; ⋯-var = λ x ϕ → refl }

open Traversal SystemF-Traversal hiding (_⋯_; ⋯-id)

fusion :  ∀  ⦃ K₁ : Kit _∋/⊢₁_ ⦄ ⦃ K₂ : Kit _∋/⊢₂_ ⦄ ⦃ K : Kit _∋/⊢_ ⦄ ⦃ W₁ : WkKit K₁ ⦄
             ⦃ C : CKit K₁ K₂ K ⦄ (t : S₁ ⊢ s) (ϕ₁ : S₁ –[ K₁ ]→ S₂) (ϕ₂ : S₂ –[ K₂ ]→ S₃) →
          (t ⋯ ϕ₁) ⋯ ϕ₂ ≡ t ⋯ (ϕ₁ ·ₖ ϕ₂)
fusion (` x)          ϕ₁ ϕ₂ = sym (&/⋯-⋯ (ϕ₁ _ x) ϕ₂)
fusion (λx t)         ϕ₁ ϕ₂ = 
  λx ((t ⋯ (ϕ₁ ↑ 𝕖)) ⋯ (ϕ₂ ↑ 𝕖))   ≡⟨ cong (λ t → λx t) (fusion t (ϕ₁ ↑ 𝕖) (ϕ₂ ↑ 𝕖)) ⟩
  λx (t ⋯ ((ϕ₁ ↑ 𝕖) ·ₖ (ϕ₂ ↑ 𝕖)))  ≡⟨ cong (λ ϕ → λx (t ⋯ ϕ)) (sym (~-ext (dist-↑-· 𝕖 ϕ₁ ϕ₂))) ⟩
  λx (t ⋯ ((ϕ₁ ·ₖ ϕ₂) ↑ 𝕖))        ∎
fusion (t₁ · t₂)      ϕ₁ ϕ₂ = cong₂ _·_  (fusion t₁ ϕ₁ ϕ₂)
                                          (fusion t₂ ϕ₁ ϕ₂)
fusion (Λα t)         ϕ₁ ϕ₂ = cong Λα_ (
  (t ⋯ (ϕ₁ ↑ 𝕥)) ⋯ (ϕ₂ ↑ 𝕥)
    ≡⟨ fusion t (ϕ₁ ↑ 𝕥) (ϕ₂ ↑ 𝕥) ⟩
  t ⋯ ((ϕ₁ ↑ 𝕥) ·ₖ (ϕ₂ ↑ 𝕥))
    ≡⟨ cong (t ⋯_) (sym (~-ext (dist-↑-· 𝕥 ϕ₁ ϕ₂))) ⟩
  t ⋯ ((ϕ₁ ·ₖ ϕ₂) ↑ 𝕥)
    ∎)
fusion (∀[α∶ t₁ ] t₂) ϕ₁ ϕ₂ =
  cong₂ ∀[α∶_]_ (fusion t₁ ϕ₁ ϕ₂) (
    (t₂ ⋯ (ϕ₁ ↑ 𝕥)) ⋯ (ϕ₂ ↑ 𝕥)
      ≡⟨ fusion t₂ (ϕ₁ ↑ 𝕥) (ϕ₂ ↑ 𝕥) ⟩
    t₂ ⋯ ((ϕ₁ ↑ 𝕥) ·ₖ (ϕ₂ ↑ 𝕥))
      ≡⟨ cong (t₂ ⋯_) (sym (~-ext (dist-↑-· 𝕥 ϕ₁ ϕ₂))) ⟩
    t₂ ⋯ ((ϕ₁ ·ₖ ϕ₂) ↑ 𝕥)
      ∎)
fusion (t₁ ∙ t₂)      ϕ₁ ϕ₂ =
  cong₂ _∙_ (fusion t₁ ϕ₁ ϕ₂) (fusion t₂ ϕ₁ ϕ₂)
fusion (t₁ ⇒ t₂)      ϕ₁ ϕ₂ =
  cong₂ _⇒_ (fusion t₁ ϕ₁ ϕ₂) (fusion t₂ ϕ₁ ϕ₂)
fusion ★              ϕ₁ ϕ₂ = refl

SystemF-CTraversal : CTraversal
SystemF-CTraversal = record { fusion = fusion }

open CTraversal SystemF-CTraversal hiding (fusion)

-- Type System -----------------------------------------------------------------

SystemF-Types : Types
SystemF-Types = record { ↑ᵗ = λ { 𝕖 → _ , 𝕥 ; 𝕥 → _ , 𝕜 ; 𝕜 → _ , 𝕜 } }

open Types SystemF-Types

private variable
  Γ Γ₁ Γ₂ Γ' Γ₁' Γ₂' : Ctx S
  T T₁ T₂ T' T₁' T₂' : S ∶⊢ s

data _⊢_∶_ : Ctx S → S ⊢ s → S ∶⊢ s → Set where
  ⊢`  :  ∀ {x : S ∋ s} {T : S ∶⊢ s} → Γ ∋ x ∶ T → Γ ⊢ ` x ∶ T
  ⊢λ  :  ∀ {e : (𝕖 ∷ S) ⊢ 𝕖} → (t₁ ∷ Γ) ⊢ e ∶ (wk 𝕖 t₂) → Γ ⊢ λx e ∶ t₁ ⇒ t₂
  ⊢Λ  :  (k ∷ Γ) ⊢ e ∶ t₂ → Γ ⊢ Λα e ∶ ∀[α∶ k ] t₂
  ⊢·  :  Γ ⊢ e₁ ∶ t₁ ⇒ t₂ → Γ ⊢ e₂ ∶ t₁ → Γ ⊢ e₁ · e₂ ∶ t₂
  ⊢∙  :  {Γ : Ctx S} → (k₂ ∷ Γ) ⊢ t₁ ∶ k₁ → Γ ⊢ t₂ ∶ k₂ → Γ ⊢ e₁ ∶ ∀[α∶ k₂ ] t₁ →
         Γ ⊢ e₁ ∙ t₂ ∶ t₁ ⋯ ⦅ t₂ ⦆
  ⊢τ  :  Γ ⊢ t ∶ ★

SystemF-Typing : Typing
SystemF-Typing = record { _⊢_∶_ = _⊢_∶_ ; ⊢` = ⊢` }

open Typing SystemF-Typing hiding (_⊢_∶_; ⊢`) 

_⊢⋯_ : ∀ ⦃ K : Kit _∋/⊢_ ⦄ ⦃ W : WkKit K ⦄ ⦃ TK : TKit K ⦄
         ⦃ C₁ : CKit K Kᵣ K ⦄ ⦃ C₂ : CKit K K K ⦄ ⦃ C₃ : CKit K Kₛ Kₛ ⦄
         {S₁ S₂ st} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {s : Sort st}
         {e : S₁ ⊢ s} {t : S₁ ∶⊢ s} {ϕ : S₁ –[ K ]→ S₂} →
       Γ₁ ⊢ e ∶ t →
       ϕ ∶ Γ₁ ⇒ₖ Γ₂ →
       Γ₂ ⊢ e ⋯ ϕ ∶ t ⋯ ϕ
⊢` ⊢x                               ⊢⋯ ⊢ϕ = ⊢`/id (⊢ϕ _ _ ⊢x)
⊢λ {t₂ = t₂} ⊢e                     ⊢⋯ ⊢ϕ = ⊢λ (subst  (λ t → _ ⊢ _ ∶ t) (sym (⋯-↑-wk t₂ _ _))
                                                       (⊢e ⊢⋯ (⊢ϕ ⊢↑ _)))
⊢Λ ⊢e                               ⊢⋯ ⊢ϕ = ⊢Λ (⊢e ⊢⋯ (⊢ϕ ⊢↑ _))
⊢· ⊢e₁ ⊢e₂                          ⊢⋯ ⊢ϕ = ⊢· (⊢e₁ ⊢⋯ ⊢ϕ) (⊢e₂ ⊢⋯ ⊢ϕ)
⊢∙ {t₁ = t₁} {t₂ = t₂} ⊢t₁ ⊢t₂ ⊢e₁  ⊢⋯ ⊢ϕ = subst  (λ t → _ ⊢ _ ∶ t) (sym (dist-↑-⦅⦆-⋯ t₁ t₂ _))
                                                   (⊢∙  (⊢t₁ ⊢⋯ (⊢ϕ ⊢↑ _))
                                                        (⊢t₂ ⊢⋯ ⊢ϕ) (⊢e₁ ⊢⋯ ⊢ϕ))
⊢τ                                  ⊢⋯ ⊢ϕ = ⊢τ

SystemF-TTraversal : TTraversal
SystemF-TTraversal = record { _⊢⋯_ = _⊢⋯_ }

open TTraversal SystemF-TTraversal hiding (_⊢⋯_)

-- Semantics -------------------------------------------------------------------

mutual
  data Neutral : S ⊢ s → Set where
    `_   : ∀ (x : S ∋ s) → Neutral (` x)
    _·_  : Neutral e₁ → Value e₂ → Neutral (e₁ · e₂)
    _∙t  : Neutral e₁ → Neutral (e₁ ∙ t₂)

  data Value : S ⊢ s → Set where
    λx_      : ∀ (e : (𝕖 ∷ S) ⊢ 𝕖) → Value (λx e)
    Λα_      : ∀ (e : (𝕥 ∷ S) ⊢ 𝕖) → Value (Λα e)
    neutral  : Neutral e → Value e

data _↪_ : S ⊢ s → S ⊢ s → Set where
  β-λ   :  ∀ {e₂ : S ⊢ 𝕖} → (λx e₁) · e₂ ↪ e₁ ⋯ ⦅ e₂ ⦆
  β-Λ   :  ∀ {t₂ : S ⊢ 𝕥} → (Λα e₁) ∙ t₂ ↪ e₁ ⋯ ⦅ t₂ ⦆
  ξ-λ   :  e ↪ e' → λx e ↪ λx e'
  ξ-Λ   :  e ↪ e' → Λα e ↪ Λα e'
  ξ-·₁  :  e₁ ↪ e₁' → e₁ · e₂ ↪ e₁' · e₂
  ξ-·₂  :  e₂ ↪ e₂' → e₁ · e₂ ↪ e₁ · e₂'
  ξ-∙₁  :  e₁ ↪ e₁' → e₁ ∙ t₂ ↪ e₁' ∙ t₂

-- Subject Reduction -----------------------------------------------------------

subject-reduction : Γ ⊢ e ∶ t → e ↪ e' → Γ ⊢ e' ∶ t
subject-reduction (⊢· {t₂ = t₂} (⊢λ ⊢e₁) ⊢e₂) β-λ =
  subst (_ ⊢ _ ∶_) (wk-cancels-⦅⦆-⋯ t₂ _) (⊢e₁ ⊢⋯ₛ ⊢⦅ ⊢e₂ ⦆ₛ)
subject-reduction (⊢∙ ⊢t₁ ⊢t₂ (⊢Λ ⊢e₁)) β-Λ =
  ⊢e₁ ⊢⋯ₛ ⊢⦅ ⊢t₂ ⦆ₛ
subject-reduction (⊢λ ⊢e) (ξ-λ e↪e') =
  ⊢λ (subject-reduction ⊢e e↪e')
subject-reduction (⊢Λ ⊢e) (ξ-Λ e↪e') =
  ⊢Λ (subject-reduction ⊢e e↪e')
subject-reduction (⊢· ⊢e₁ ⊢e₂) (ξ-·₁ e₁↪e₁') =
  ⊢· (subject-reduction ⊢e₁ e₁↪e₁') ⊢e₂
subject-reduction (⊢· ⊢e₁ ⊢e₂) (ξ-·₂ e₂↪e₂') =
  ⊢· ⊢e₁ (subject-reduction ⊢e₂ e₂↪e₂')
subject-reduction (⊢∙ ⊢t₁ ⊢t₂ ⊢e₁) (ξ-∙₁ e₁↪e₁') =
  ⊢∙ ⊢t₁ ⊢t₂ (subject-reduction ⊢e₁ e₁↪e₁')
