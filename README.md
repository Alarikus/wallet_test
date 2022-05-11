# Wallet Test
- The application includes two lists on the same screen
- The first list is a list of wallets the user has
- The second list is a list of transactions the user has performed, paginated
- Tapping on an item on second list, leads user to a details screen (History Details Screen)
- The application supports handling two types of errors (429 with custom error message and 500)
- The application supports delay for each request

## Mock Data
- GET /wallets - returns list of user wallets
	`‌{
  "wallets": [
    {
      "id": "1001",
      "wallet_name": "PHP",
      "balance": "1000.23"
    }
  ]
}`
- GET /history - returns list of user transactions
`{
  "data": [
    {
      "id": "2001",
      "entry": "incoming",
      "amount": "100.23",
      "currency": "PHP",
      "partner": "John",
      "date": "1996-12-19T16:39:57-08:00"
    }
  ],
  "pageCount": 3
}`
