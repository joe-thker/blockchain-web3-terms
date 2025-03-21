;; This is a simple Clarity smart contract for a Bitcoin dApp on the Stacks blockchain.

(define-data-var greeting (string-utf8 32) "Hello, Bitcoin dApp!")

(define-public (set-greeting (new-greeting (string-utf8 32)))
  (begin
    (var-set greeting new-greeting)
    (ok new-greeting)
  )
)

(define-public (get-greeting)
  (ok (var-get greeting))
)
