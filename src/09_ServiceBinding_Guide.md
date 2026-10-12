# Service Binding: ZMTO_SB_ExcessStock — ADT Configuration Guide

This artifact cannot be generated as source code. It is created exclusively through
the ABAP Development Tools (ADT) wizard in Eclipse. Follow the steps below.

---

## Prerequisites

| Step | Artifact | Must be active before binding |
|------|----------|-------------------------------|
| 1 | `ZR_MTO_ExcessStock` (Root CDS) | ✅ |
| 2 | `ZC_MTO_ExcessStock` (Projection CDS) | ✅ |
| 3 | `ZMTO_SD_ExcessStock` (Service Definition) | ✅ |
| 4 | `ZBP_R_MTO_EXCESS_STOCK` (Behavior Handler) | ✅ |

---

## Step-by-Step Instructions

### 1. Open the Service Definition in ADT
In the **Project Explorer**, navigate to:
```
<Your ABAP Project>
  └── Cloud Objects / Other Objects
        └── Service Definitions
              └── ZMTO_SD_ExcessStock
```

### 2. Create a New Service Binding
Right-click `ZMTO_SD_ExcessStock` → **New Service Binding**.

Fill in the wizard fields:

| Field | Value |
|-------|-------|
| **Name** | `ZMTO_SB_ExcessStock` |
| **Description** | `MTO Excess Stock Transfer – UI Binding` |
| **Binding Type** | `OData V4 - UI` |

Click **Next** → **Finish**.

### 3. Activate the Service Binding
In the Service Binding editor that opens:
1. Click **Activate** (the green circle icon in the toolbar).
2. Wait for the activation to complete — the status line should show `Active`.

### 4. Publish the Service
Click **Publish Locally** in the editor toolbar.  
This makes the service available under the local service registry.

### 5. Note the Service URL
After publication the editor displays a **Service URL** in the format:
```
/sap/opu/odata4/sap/zmto_sb_excessstock/srvd/sap/zmto_sd_excessstock/0001/
```
Copy this URL — it is needed for the Fiori Launchpad tile configuration.

---

## Fiori Launchpad Tile Configuration (Optional)

To create a tile in the Fiori Launchpad that opens the List Report app:

1. Open **Fiori Launchpad Designer** (transaction `/n/UI2/FLPD_CONF` or browser URL).
2. Create a new **App Descriptor** tile:
   - App ID: `zmto_excessstock`
   - Component URL: From the published binding above
   - Intent: `ExcessStock-manage` (example)
3. Assign the tile to the appropriate group and role.

---

## Quick Test via Service Binding Editor

Without deploying a tile, you can preview the app directly from the Service Binding editor:

1. In ADT, open `ZMTO_SB_ExcessStock`.
2. In the **Entity Set and Association** table, find `ExcessStock`.
3. Click the **Preview** button (requires a browser with an active S/4HANA system session).

This opens the Fiori Elements List Report app in a browser for immediate testing.

---

## Summary of All Custom Objects

| Object Name | Type | Description |
|-------------|------|-------------|
| `ZR_MTO_ExcessStock` | CDS View Entity (Root) | Stock data from I_MaterialInventoryStock |
| `ZC_MTO_ExcessStock` | CDS View Entity (Projection) | UI projection with ClassificationText virtual element |
| `ZMTO_A_TransferParams` | Abstract Entity | Action popup parameter fields |
| `ZMTO_ME_ExcessStock` | Metadata Extension | All UI annotations |
| `ZCL_MTO_CALC_CHARS` | ABAP Class | Virtual element calculation (classification read) |
| `ZBP_R_MTO_EXCESS_STOCK` | ABAP Class (Behavior) | Action handler + BAPI saver |
| `ZMTO_SD_ExcessStock` | Service Definition | OData service exposure |
| `ZMTO_SB_ExcessStock` | Service Binding | OData V4 UI binding (created in ADT) |