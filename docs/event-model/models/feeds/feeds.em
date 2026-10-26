model "Feeds"

persona User

context Connection
context SyncRun

slice "Connect SimpleFIN" {
  ui Provider Connection Screen @User
  command Connect SimpleFIN
  event SimpleFIN Connection Established @Connection
}

slice "Discover Provider Accounts" {
  view Discovered Accounts from "SimpleFIN Connection Established"
  ui Account Selection Screen @User
}

slice "Start Provider Sync" {
  ui Connection Status Screen @User
  command Start Provider Sync
  event Provider Sync Started @SyncRun
}

slice "Request SimpleFIN Data" {
  view Pending Provider Sync from "Provider Sync Started"
}

slice "Receive Provider Data" {
  translation SimpleFIN Data Adapter from "Pending Provider Sync"
  command Receive Provider Data
  event Provider Data Received @SyncRun
}

slice "Receive Provider Sync Failure" {
  translation SimpleFIN Failure Adapter from "Pending Provider Sync"
  command Record Provider Sync Failure
  event Provider Sync Failed @SyncRun
}

slice "Normalize Provider Data" {
  view Provider Data Pending Normalization from "Provider Data Received"
  translation Provider Data Normalizer from "Provider Data Pending Normalization"
}

slice "Record Normalized Provider Data" {
  command Record Normalized Provider Data
  event Provider Data Normalized @SyncRun public
}
arrow Provider Data Normalizer -> Record Normalized Provider Data

slice "Schedule Recurring Sync" {
  view Due Connections from "Provider Sync Started"
  processor Recurring Sync Scheduler
}

slice "Start Scheduled Provider Sync" {
  command Start Scheduled Provider Sync
  event Scheduled Provider Sync Started @SyncRun
}
arrow Recurring Sync Scheduler -> Start Scheduled Provider Sync

slice "Retry Failed Sync" {
  view Failed Syncs from "Provider Sync Failed"
  processor Sync Retry Automation
}

slice "Retry Provider Sync" {
  command Retry Provider Sync
  event Provider Sync Retry Started @SyncRun
}
arrow Sync Retry Automation -> Retry Provider Sync

slice "Request Manual Sync" {
  ui Connection Status Screen @User
  command Request Manual Sync
  event Manual Sync Requested @Connection
}

slice "Review Sync Status" {
  view Connection Sync Status from "Provider Sync Started", "Scheduled Provider Sync Started", "Provider Sync Retry Started", "Provider Sync Failed", "Manual Sync Requested"
  ui Connection Status Screen @User
}

slice "Show Manual Sync Status" {
  view Connection Sync Status again from "Manual Sync Requested"
  ui Connection Status Screen @User
}
