# ZMTO_CHARC_CHK — Create via SE11 (Transparent Table)

## Table Properties
| Property | Value |
|----------|-------|
| Table Name | `ZMTO_CHARC_CHK` |
| Description | MTO Transfer - Characteristic Check Config |
| Delivery Class | C (Customizing table) |
| Data Maintenance | Display/Maintenance Allowed |

## Fields

| Field | Key | Data Element / Type | Length | Description |
|-------|-----|---------------------|--------|-------------|
| MANDT | ✓ | MANDT | 3 | Client |
| CHARC_NAME | ✓ | CHAR30 (or ATNAM) | 30 | Characteristic Name |
| CDS_FIELD_NAME | | CHAR30 | 30 | CDS Field Name in ZR_MTO_SoItemCharcVals |
| DESCRIPTION | | CHAR60 | 60 | Description |
| ACTIVE | | CHAR1 | 1 | Active Flag (X = check) |

## Steps in SE11

1. Go to **SE11** → Enter table name `ZMTO_CHARC_CHK` → Create
2. Set **Delivery Class** = `C`, **Data Browser/Table View Maint.** = `Display/Maintenance Allowed`
3. Add fields as listed above (MANDT + CHARC_NAME as key fields)
4. Go to **Technical Settings**: Data Class = `APPL0`, Size Category = `0`
5. Activate the table
6. Generate **Table Maintenance Generator**: Go to Utilities → Table Maintenance Generator
   - Authorization Group: `&NC&`
   - Function Group: `ZMTO_CHARC_CHK`
   - Maintenance Type: One Step
   - Generate

## Sample Data (insert via SM30 or SE16N)

| CHARC_NAME | CDS_FIELD_NAME | DESCRIPTION | ACTIVE |
|------------|---------------|-------------|--------|
| ZWIDTH | Width | Width must match | X |
| Z_F_ALLOY | FlexAlloy | Flex Alloy must match | X |
| ZCATEGORY_R | CategoryRigid | Rigid category must match | X |
| ZMICRON | Micron | Micron must match | X |

## CDS Field Name Mapping Reference

These are the field aliases from `ZR_MTO_SoItemCharcVals` that you can use in the `CDS_FIELD_NAME` column:

### Character-type fields:
- `PalletType`, `MaterialText`, `MaterialNumber`, `MaterialNumber1`
- `ChannelExpLoc`, `Process`, `Micron`, `Width`, `BoxType`
- **Rigid**: `CategoryRigid`, `GramRigid`, `VersionRigid`, `ColorRigid`, `NeckringRigid`, `LogoRigid`, `AdditivesRigid`, `InnerQtyRigid`, `ColorLdrRigid`
- **Flexible**: `CategoryFlex`, `SubCategoryFlex`, `RecipeFlex`, `CoreFlex`, `DesignNumberFlex`, `PriceCombFlex`, `FlexWidth`, `FlexAlloy`, `FlexCoreMaterial`, `FlexUnwindDir`

### Numeric-type fields:
- `PalletWeight10`, `BoxWeight`, `NetWeight`, `NetWeightSO`, `GrossWeight`
- **Flexible**: `PalletWeight1Flex`, `BoxWeightFlex`, `FlexAlThickness`, `FlexFoilThickness`, `FlexPaperThickness`