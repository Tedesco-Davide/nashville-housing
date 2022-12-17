---- Cleaning Data in SQL Queries -----

SELECT * 
FROM NashvilleHousing.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate, 105)

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate

USE NashvilleHousing
EXEC SP_RENAME
@objname = 'NashvilleHousing.dbo.NashvilleHousing.SaleDateConverted', 
@newname = 'SaleDate', 
@objtype = 'COLUMN'

SELECT SaleDate
FROM NashvilleHousing.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing
WHERE ParcelID LIKE '%025 07 0 031.00%'

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing.dbo.NashvilleHousing AS a
JOIN NashvilleHousing.dbo.NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE NashvilleHousing
SET PropertyAddress = ISNULL(NashvilleHousing.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing.dbo.NashvilleHousing AS NashvilleHousing
JOIN NashvilleHousing.dbo.NashvilleHousing AS b
	ON NashvilleHousing.ParcelID = b.ParcelID
	AND NashvilleHousing.[UniqueID ] != b.[UniqueID ]
WHERE NashvilleHousing.PropertyAddress IS NULL

--------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Property Address into Individual Columns (Address, City)

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing

SELECT 
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) AS City
FROM NashvilleHousing.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
ADD Property_Address NVARCHAR(255), Property_City NVARCHAR(255)

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET Property_Address = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
Property_City = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress))

SELECT PropertyAddress, Property_Address, Property_City 
FROM NashvilleHousing.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
DROP COLUMN PropertyAddress

USE NashvilleHousing
EXEC SP_RENAME
@objname = 'NashvilleHousing.dbo.NashvilleHousing.Property_Address', 
@newname = 'PropertyAddress', 
@objtype = 'COLUMN'

USE NashvilleHousing
EXEC SP_RENAME
@objname = 'NashvilleHousing.dbo.NashvilleHousing.Property_City ', 
@newname = 'PropertyCity ', 
@objtype = 'COLUMN'

SELECT PropertyAddress, PropertyCity 
FROM NashvilleHousing.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Owner Address into Individual Columns (Address, City, State)

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS 'OwnerAddress',
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS 'OwnerCity',
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS 'OwnerState'
FROM NashvilleHousing.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
ADD Owner_Address NVARCHAR(255), OwnerCity NVARCHAR(255), OwnerState NVARCHAR(255)

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT OwnerAddress, Owner_Address, OwnerCity, OwnerState
FROM NashvilleHousing.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
DROP COLUMN OwnerAddress

USE NashvilleHousing
EXEC SP_RENAME
@objname = 'NashvilleHousing.dbo.NashvilleHousing.Owner_Address', 
@newname = 'OwnerAddress', 
@objtype = 'COLUMN'

SELECT OwnerAddress, OwnerCity, OwnerState
FROM NashvilleHousing.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------

-- Change all Y and N, to Yes and No, in "Sold as Vacant" field

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN  SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END AS TEST
FROM NashvilleHousing.dbo.NashvilleHousing

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET SoldAsVacant = 	
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN  SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END

--------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS (
SELECT *, 
ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY UniqueID
) AS row_num
FROM NashvilleHousing.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1