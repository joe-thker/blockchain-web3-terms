;; This is a simple NFT contract written in Clarity for the Stacks blockchain,
;; which enables the creation of Bitcoin NFTs (secured by Bitcoin via Stacks).

;; Define a map to store the owner of each token.
(define-map owners ((token-id uint)) { owner: principal })

;; Define a map to store metadata for each token (e.g., a URI pointing to art or details).
(define-map token-metadata ((token-id uint)) { uri: (string-utf8 256) })

;; Data variable to track the total supply (also used to assign token IDs).
(define-data-var total-supply uint 0)

;; Public function to mint a new NFT.
(define-public (mint (recipient principal) (uri (string-utf8 256)))
  (let ((new-token-id (var-get total-supply)))
    (begin
      ;; Set the owner for the new token.
      (map-set owners { token-id: new-token-id } { owner: recipient })
      ;; Set the metadata for the new token.
      (map-set token-metadata { token-id: new-token-id } { uri: uri })
      ;; Increment the total supply.
      (var-set total-supply (+ new-token-id u1))
      (ok new-token-id)
    )
  )
)

;; Public function to get the owner of a given token.
(define-public (get-owner (token-id uint))
  (match (map-get owners { token-id: token-id })
    owner-entry (ok (get owner owner-entry))
    (err "Token does not exist")
  )
)

;; Public function to get the metadata (URI) of a given token.
(define-public (get-token-uri (token-id uint))
  (match (map-get token-metadata { token-id: token-id })
    metadata-entry (ok (get uri metadata-entry))
    (err "Token does not exist")
  )
)

;; Public function to get the total supply of minted tokens.
(define-public (get-total-supply)
  (ok (var-get total-supply))
)
