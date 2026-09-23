---
name: file-travel-emails
description: File new or accumulated trip-confirmation emails from the appropriate Inboxes into existing or newly created trip-specific Apple Mail folders. Use for a single personal or business trip, or to clean up Inbox travel mail across several upcoming trips.
---

# File Travel Emails

Organize trip mail in Apple Mail while keeping promotions and unrelated travel mail out of the trip folder.

## Interpret the request

Support both focused and batch requests:

- `File personal travel emails for 2026-10-SanDiego` means reuse that trip folder and file any newly arrived matching Inbox messages. The folder need not be newly created.
- `File business travel emails for <trip name>` does the same under the business hierarchy.
- `Clean up personal travel emails` or `Clean up business travel emails` means match accumulated Inbox confirmations to the existing folders for upcoming trips and process every confident match.

For a focused request, use the existing trip folder name and contents to recover the dates, destination, travelers, confirmation numbers, and vendors when the user does not repeat them. For a batch cleanup, inspect the upcoming trip folders under the applicable parent and use their names and existing contents as the matching reference. Do not create a trip merely from promotional mail. Leave a message in the Inbox and report it when its trip cannot be identified confidently.

## Identify the trip type

The request should identify the trip as `personal` or `business`. If it does not and the account or destination hierarchy is not otherwise explicit, ask which type before moving mail.

- Personal: search both `fjhickernell@gmail.com` and `ehickernell@gmail.com`. File matching messages under `fjhickernell@gmail.com` > `Travel`.
- Business: search `hickernell@illinoistech.edu`. File matching messages under that account's `ConferencesTrips` folder.

Use account addresses as authoritative. Apple Mail may display these accounts as `Fred Personal`, `Elaine Google`, and `Illinois Tech`.

## Resolve or create the trip folder

Use a folder name supplied by the user. Otherwise infer a concise name from the trip dates and destination or event, consistent with sibling folders, such as `2026-10-SanDiego`. Add the start day or event name when needed to avoid ambiguity.

Reuse an existing exact trip folder. If none exists and the trip is sufficiently identified, create it beneath the correct personal or business parent folder. During a batch cleanup, create a missing folder only when a genuine confirmation establishes a distinct trip and its dates and destination or event are unambiguous.

## Find the relevant Inbox messages

Search only the applicable Inboxes unless the user asks for a broader search. Use the destination, travel dates, traveler names, and confirmation numbers to distinguish this trip from older or future trips.

When a credit or certificate may be involved, search the source Inbox by distinctive subject text before searching by amount or using All Mailboxes. Start with durable phrases such as `travel certificate`, `electronic travel certificate`, `future flight credit`, and `travel credit`; use full subjects such as `You've received an electronic travel certificate from United` only as additional narrowing because airline wording may change. If the user supplies an exact subject and received date, treat that combination as authoritative identification of the requested message. In Apple Mail, confirm that the result's mailbox column names the intended Inbox and inspect the full message; broad sender searches can mix Inbox, Important, Archive, and Trash copies, while generated summaries may omit the certificate amount. Do not conclude that a message is absent from amount-only or All Mailboxes results.

Likely sources include:

- United and Junova for flights
- Marriott Bonvoy or another hotel or lodging provider
- a rental-car company when the trip includes a car

Do not rely on sender names alone. Useful trip mail includes booking confirmations, eTicket itineraries and receipts, material itinerary changes, Junova tracking confirmations, completed fare-reduction confirmations, matching airline travel-credit, future-flight-credit, or certificate notices, hotel reservation confirmations, rental-car confirmations, and other messages containing concrete trip details.

Exclude promotions, points offers, general destination newsletters, generic fare or price advertising, unrelated travel credits or certificates, and messages for a different trip. A price alert without a material itinerary change is not a confirmation. File a credit or certificate only when its amount, confirmation number, ticket number, dates, or surrounding fare-reduction message ties it to the trip; do not file older credits or certificates merely because they appeared in search results. Do not add rental-car mail when the trip has no rental car.

Avoid double-counting Mail's `Top Hits` and `All Results` views. Multiple genuine messages with the same confirmation number may be kept when they represent a booking confirmation, ticket receipt, or meaningful update rather than a duplicated search result.

## File and verify

Move each matched Inbox message into the trip folder, including a personal-trip message found in Elaine's Gmail Inbox when it belongs with Fred's personal travel folder. Leave messages already in that folder and excluded or ambiguous messages untouched.

Verify the final trip folder contents and that the moved messages no longer remain in their source Inboxes. For a focused request, report the number filed, summarize the included categories, and mention an expected category that was not found when that information may help the user. For a batch cleanup, report the number filed per trip and list any ambiguous travel messages left in the Inbox.
