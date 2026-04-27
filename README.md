# Appointment Scheduler with Provider Availability

Build a multi-provider appointment booking system where service providers configure their weekly availability and clients browse open slots, book appointments, and join waitlists when fully booked. The system enforces buffer times between bookings and handles the waitlist-to-hold promotion lifecycle when cancellations occur.

## Stack

- **Frontend**: Port **3000** (pure React, no UI framework)
- **Backend**: Port **3001** (FastAPI)
- **Persistence**: PostgreSQL, schema `appointments`

## Navigation

The page has a persistent nav bar at the top with two views: **Provider Dashboard** and **Client Booking**. Switching between them does not reload the page.

A **Delete All Data** button lives in the nav bar. Clicking it immediately wipes every provider, availability schedule, booking, and waitlist entry from the database. The UI resets to a blank state — no confirmation dialog required.

## Provider Dashboard

The Provider Dashboard is where operators register providers and manage their configurations. It shows a registration form followed by a list of all registered providers, each with their own configuration panel and booking list.

### Registering a Provider

A form at the top of the dashboard accepts a provider name and a short service description. Submitting the form creates the provider and displays a unique provider ID alongside their record. That ID is visible in the UI and used to reference the provider going forward.

### Provider Configuration

Each provider has a self-contained configuration panel with the following controls:

**Appointment duration** — a dropdown with two options: 30 minutes or 60 minutes. This is the fixed length of every appointment booked with that provider.

**Buffer time** — a dropdown with three options: 0, 15, or 30 minutes. Buffer time is dead time enforced *after* each appointment ends. The next bookable slot cannot start until the buffer period has fully elapsed. For example, a 30-minute appointment ending at 09:30 with a 15-minute buffer means the earliest next slot is 09:45.

**Weekly availability** — a grid of weekdays Monday through Friday. Each day has an on/off toggle. When a day is enabled, it shows at least one time block with a start time and an end time, each selectable in 30-minute increments. Additional time blocks can be added to the same day (to model gaps like a lunch break). Time blocks that overlap or are otherwise invalid should be prevented. A Save button commits the availability configuration for that provider.

### Upcoming Bookings

Below the configuration panel, each provider has a list of their upcoming bookings. Each entry shows the client's name, the date, and the start time of the appointment. A **Cancel** button on each entry cancels that booking. Cancellation frees the slot and, if there is a waitlist for that provider on that day, triggers the reservation hold flow described below.

## Client Booking

The Client Booking view shows all registered providers as clickable cards. Each card displays the provider's name and service description. Clicking a card reveals that provider's available slots.

### Viewing Available Slots

The system computes open slots for the **next 5 weekdays** (Monday through Friday, starting from tomorrow). For each day within a provider's enabled availability, the system generates slots at appointment-duration intervals starting from the day's first available time. A slot is only shown if:

- It falls within one of the provider's availability blocks for that day.
- The entire appointment duration fits within the block.
- The slot does not overlap with an existing booking or with that booking's buffer period.
- The slot is not currently under a reservation hold for another user.

Each available slot is rendered as a button. Clicking a slot opens an inline form asking the client for their name. Submitting the form books the slot immediately. The slot disappears from the list and the booking appears in the provider's dashboard.

If a particular day has **no available slots** (all booked or all held), a **Join Waitlist** button appears for that day instead of any slots. Clicking it opens an inline form asking for the client's name. Submitting adds the client to the end of the waitlist for that provider and day. The UI acknowledges their position.

### Reservation Hold

When a provider cancels a booking, the system checks for a waitlist for that provider on that day. If one exists, the **first person** on the waitlist receives a reservation hold on the freed slot.

From the perspective of the client who holds the reservation: the slot they're waiting for appears in their view with a visible countdown timer and a **Confirm Booking** button. The timer starts at 60 seconds and counts down in real time. The client must click **Confirm Booking** before the timer reaches zero to secure the booking.

During the hold period, the slot is invisible to all other clients browsing that provider's availability.

If the hold expires without confirmation, the slot is released. It is then offered to the next person on the waitlist (same hold mechanics) or, if the waitlist is now empty, the slot becomes generally available.

### Concurrency

If two clients attempt to book the same slot simultaneously, exactly one request succeeds. The other client sees a clear error message indicating the slot is no longer available. The successful booking is immediately reflected in availability for all other clients.

## Persistence

All data — providers, availability schedules, bookings, and waitlist entries — must survive a backend restart. Reloading the page after a restart must restore the complete state.

## `data-testid` Reference

Every interactive and observable element must carry the exact `data-testid` shown below.

### Navigation

- `nav-provider` — Provider Dashboard nav button
- `nav-client` — Client Booking nav button
- `delete-all-btn` — Delete All Data button

### Provider Dashboard

- `provider-view` — outer container of the Provider Dashboard

**Registration form:**
- `provider-name-input` — text input for the new provider's name
- `provider-service-input` — text input for the service description
- `register-provider-btn` — submit button to create the provider

**Per-provider panel** — `{providerId}` is the unique ID returned by the backend:
- `provider-id-{providerId}` — element displaying the provider's ID
- `duration-select-{providerId}` — appointment duration dropdown; option values are `"30"` and `"60"`
- `buffer-select-{providerId}` — buffer time dropdown; option values are `"0"`, `"15"`, and `"30"`
- `day-toggle-{providerId}-{day}` — enable/disable toggle for a weekday; `{day}` is the full lowercase day name: `monday`, `tuesday`, `wednesday`, `thursday`, `friday`
- `add-time-block-{providerId}-{day}` — button to add an additional time block for that day
- `time-block-start-{providerId}-{day}-{index}` — start time selector for block at zero-based `{index}`
- `time-block-end-{providerId}-{day}-{index}` — end time selector for block at zero-based `{index}`
- `remove-time-block-{providerId}-{day}-{index}` — button to remove a time block
- `save-availability-{providerId}` — button to persist availability changes for this provider

**Bookings list:**
- `booking-item-{bookingId}` — a row in the upcoming bookings list
- `cancel-booking-{bookingId}` — cancel button within a booking row

### Client Booking

- `client-view` — outer container of the Client Booking view
- `provider-card-{providerId}` — clickable provider card

**Slots and waitlist** — `{day}` is the full lowercase weekday name; `{time}` is the 24-hour start time with no colon, zero-padded to 4 digits (e.g., `0900`, `1430`):
- `slot-{day}-{time}` — an available slot button (e.g., `slot-monday-0900`)
- `join-waitlist-{day}` — join waitlist button shown when a day has no available slots

**Booking a slot:**
- `client-name-input` — text input for the client's name when booking a slot
- `confirm-booking-btn` — button to confirm the slot booking

**Joining the waitlist:**
- `waitlist-name-input` — text input for the client's name when joining the waitlist
- `join-waitlist-confirm-btn` — button to submit the waitlist entry

**Reservation hold:**
- `hold-timer` — countdown display during a reservation hold; text content is the remaining whole seconds (e.g., `"60"`, `"59"`, …, `"1"`)
- `confirm-hold-btn` — button to confirm the booking during an active hold
