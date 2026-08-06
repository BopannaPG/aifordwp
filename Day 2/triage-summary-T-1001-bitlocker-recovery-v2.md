# Structured Triage Summary

## Summary (one line)
Ticket T-1001 reports a new Windows 11 laptop prompts for a BitLocker recovery key at every boot.

## Impact (who/how many/business urgency)
- Who is affected: User of the reported new Windows 11 laptop (to-verify).
- How many affected: One reported user/device (to-verify if wider).
- Business urgency: Repeated startup recovery prompts may delay or block access to work systems (urgency to-verify).

## known facts
- Ticket reference: T-1001.
- Device is described as a new Windows 11 laptop.
- BitLocker recovery key prompt appears at every boot.

## Missing information to gather
- Exact user identity and device asset/hostname details (to-verify via ticket records).
- Whether the user can enter the recovery key successfully and sign in.
- When the issue started and whether it happens on every restart without exception.
- Any recent firmware/BIOS/security configuration changes.
- Any recent hardware changes (for example dock, USB, storage, repair activity).
- Whether similar behavior is reported on other new Windows 11 devices.
- Current management/join status and latest policy sync state (to-verify).

## likely catagory
- Endpoint Security / BitLocker Recovery Prompt Loop (to-verify).

## First diagnostic step
- Confirm the stored recovery key for this exact device in management records, then perform one controlled unlock-and-restart check to verify whether the prompt repeats (to-verify result).
