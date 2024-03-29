SELECT * FROM DataCleaning..NashvilleHousing

-- Standardize the data format
SELECT SaleDate, CONVERT(Date, SaleDate) FROM DataCleaning..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Populate Property Address Data

SELECT * FROM DataCleaning..NashvilleHousing
WHERE PropertyAddress IS NULL

SELECT * FROM DataCleaning..NashvilleHousing
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning..NashvilleHousing a
JOIN DataCleaning..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning..NashvilleHousing a
JOIN DataCleaning..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


-- Breaking Out PropertyAddress  & OwnerAddress  into individual columns (Address, City, State)

--1st: PropertyAddress

SELECT PropertyAddress FROM DataCleaning..NashvilleHousing

----Address
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
FROM DataCleaning..NashvilleHousing

----City
SELECT SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM DataCleaning..NashvilleHousing


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) 


ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-- 2nd: Owner Address

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as Address,
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as City,
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as State 
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) FROM DataCleaning..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)

SELECT SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM DataCleaning..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant =
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END


-- Remove Duplicates

WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER (PARTITION BY ParcelID,
									PropertyAddress,
									SalePrice,
									SaleDate,
									LegalReference
								ORDER BY UniqueID) row_num
FROM DataCleaning..NashvilleHousing)

--SELECT * FROM RowNumCTE
--WHERE row_num > 1
--ORDER BY PropertyAddress

DELETE FROM RowNumCTE
WHERE row_num > 1


-- Delete Unused Columns (not advised)

ALTER TABLE DataCleaning..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

SELECT * FROM DataCleaning..NashvilleHousing
