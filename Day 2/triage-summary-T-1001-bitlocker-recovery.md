# Structured Triage Summary

## Summary (one line)
Ticket T-1001 reports a new Windows 11 laptop is prompting for the BitLocker recovery key at every boot.

## Impact (who/how many/business urgency)
- Who is affected: User of the new Windows 11 laptop (to-verify).
- How many affected: One reported device/user (to-verify if wider).
- Business urgency: Repeated recovery-key prompts at startup may block or delay access to work (urgency level to-verify).

## known facts
- Ticket reference: T-1001.
- Device is described as a new Windows 11 laptop.
- BitLocker recovery key prompt appears on every boot.

## Missing information to gather
- Exact user and device identity/asset details (to-verify via ticketing records).
- When the behavior started and whether it has occurred on every reboot since first use.
- Whether the user can successfully enter the recovery key and then sign in.
- Whether any recent firmware/BIOS/boot-order/security setting changes were made.
- Whether hardware changes (dock, USB devices, storage, motherboard/service actions) occurred.
- Whether this affects only one laptop model or multiple new Win11 devices.
- Whether device is domain-joined/managed and policy sync status.

## likely catagory
- Endpoint Security / BitLocker Startup Recovery Loop (to-verify).

## First diagnostic step
- Verify in management records that the recovery key for this exact device matches what the user is being prompted for, then confirm whether the prompt reoccurs after one successful unlock and normal restart (to-verify result).
