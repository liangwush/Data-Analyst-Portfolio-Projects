/*

Cleaning Data in SQL Queries
import NashvilleHousing.xlsx  file

*/

/*
Some USEFUL functions to process string

1. trim()
-- Removing leading and trailing spaces, hyphens, and slashes
SELECT TRIM(BOTH ' -/' FROM your_column) AS stripped_column
FROM your_table;

2. replace()
-- Removing hyphens and slashes from the middle of the string
SELECT REPLACE(your_column, '-', '') AS stripped_column
FROM your_table;

3. regexp_replace()
-- Removing characters that are not letters or digits
SELECT REGEXP_REPLACE(your_column, '[^a-zA-Z0-9]', '') AS stripped_column
FROM your_table;

*/


Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


Select SaleDate, CONVERT(Date,SaleDate) as SaleDateConverted
From PortfolioProject.dbo.NashvilleHousing


Update PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)



-- If it doesn't Update properly

-- The following block of code is for testing purpose when run the codes below several times
USE PortfolioProject;
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'NashvilleHousing' AND COLUMN_NAME = 'SaleDateConverted'
)
BEGIN
    ALTER TABLE NashvilleHousing
    DROP COLUMN SaleDateConverted;
END;

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add SaleDateConverted Date;

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

Select SaleDate,SaleDateConverted
From PortfolioProject.dbo.NashvilleHousing
go;


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data for null address

Select *
From PortfolioProject.dbo.NashvilleHousing
--Check null address
--Where PropertyAddress is null 
order by ParcelID


-- Find the addresses with null values which will fill in the blank of addresss
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

-- Process Property Address
Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID
-- CHARINDEX(',', PropertyAddress) is to find ',' position/index in string PropertyAddress
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address

From PortfolioProject.dbo.NashvilleHousing;

-- Add 2 columns
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))




Select *
From PortfolioProject.dbo.NashvilleHousing




--Process Owner's Address,try to use parsename instead of substring()
Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing

-- parsename only work with '.' period. Also the section number is count from right to left, so 1 is state 3 is address
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) -- Parsename ONLY work with '.' as seperate
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From PortfolioProject.dbo.NashvilleHousing


-- Add 3 columns
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
Go


Select *
From PortfolioProject.dbo.NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

-- Use Distinct() to view the variants
Select Distinct(SoldAsVacant), Count(SoldAsVacant) as Cnt
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by Cnt desc



Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
  END
From PortfolioProject.dbo.NashvilleHousing

-- Set/Update
Update PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = 
	CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	END






-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
-- the following must be implement imediately, same batch
Select *
--delete
From RowNumCTE
Where row_num > 1
Order by PropertyAddress
go

/*
-- or use the following
-- Create a new table without duplicate rows
SELECT DISTINCT *
INTO TempTable
FROM PortfolioProject.dbo.NashvilleHousing

-- Drop the original table
DROP TABLE PortfolioProject.dbo.NashvilleHousing

-- Rename the new table to the original table name
EXEC sp_rename 'TempTable', 'NashvilleHousing';
*/






Select *
From PortfolioProject.dbo.NashvilleHousing;




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



Select *
From PortfolioProject.dbo.NashvilleHousing


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate















-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO

















