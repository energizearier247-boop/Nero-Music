# Nero Music monthly subscriptions — implementation status

## Included in this project update
- A Listener Premium screen at **Profile → Premium membership**, showing the proposed ₦2,000/month price.
- The Earnings tab is now an owner-revenue overview, not an artist royalty screen.
- A Supabase schema for subscription status and verified payment records, with row-level security that permits users to read only their own records.
- The app requests a checkout URL from the `create-subscription-checkout` Supabase Edge Function. It does not treat a button tap or a stream as a payment.

## Required before taking real payments
1. Confirm the listener price and decide the separate DJ plan price.
2. Deploy a secure `create-subscription-checkout` Edge Function that creates Paystack checkout sessions server-side.
3. Deploy a Paystack webhook handler that verifies Paystack's signature and transaction status before updating the tables.
4. Configure Paystack secret credentials as Supabase Edge Function secrets. Do not put them in Flutter, GitHub source, or chat.
5. Configure subscription renewals/cancellations and verify recurring billing behavior with Paystack before launch.
6. Configure an owner role and owner-only revenue reporting. The Earnings screen currently shows a clearly marked empty state; it does not claim live financial totals.
7. Obtain the necessary rights for music streaming and commercial DJ use, and clearly disclose the subscription terms to users.

The checkout function is intentionally not faked or treated as successful. Until the server functions are deployed and tested, the app will tell users that checkout is not configured and no payment has been taken.
