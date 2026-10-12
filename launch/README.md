# MACRO'S — Kit di lancio

Strumenti per la strategia di lancio a capitale minimo: Early Access → Ghost Kitchen a Milano → primo ristorante → replica.

| File | A cosa serve |
| --- | --- |
| `early-access.html` | Landing MACRO'S Early Access: email, città, obiettivo, pasti a settimana, spesa a pasto, codice invito (`?ref=CODICE`) e UTM. |
| `supabase_early_access.sql` | Tabella `early_access`, funzione `join_early_access` usata dalla landing e vista `early_access_by_city` (classifica delle città). Da eseguire una volta nel SQL Editor di Supabase. |
| `MACROS_modello_finanziario.xlsx` | Modello finanziario: ipotesi, budget Fasi 0–1, conto economico della Ghost Kitchen, investimento del ristorante, capitale a rischio e stage gate. Le celle blu sono le ipotesi da modificare. |

## Messa online della landing

1. Esegui `supabase_early_access.sql` nel progetto Supabase già usato dal totem.
2. Pubblica il repository (o solo `early-access.html`) su GitHub Pages o sul dominio MACRO'S.
3. Usa link con UTM per misurare i canali, ad esempio `early-access.html?utm_source=instagram&utm_campaign=basalari_annuncio`.

La tabella non è accessibile dal browser: la landing passa solo dalla funzione `join_early_access`. La classifica delle città si legge dalla dashboard Supabase con `select * from early_access_by_city;`.
