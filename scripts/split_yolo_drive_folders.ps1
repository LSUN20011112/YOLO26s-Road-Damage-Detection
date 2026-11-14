param(
    [int]$ChunkSize = 5000
)

$ErrorActionPreference = 'Stop'

if ($ChunkSize -lt 1 -or $ChunkSize -ge 10000) {
    throw 'ChunkSize must be between 1 and 9999.'
}

$datasetRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$imageRoot = Join-Path $datasetRoot 'images'
$labelRoot = Join-Path $datasetRoot 'labels'

if (-not (Test-Path -LiteralPath $imageRoot -PathType Container)) {
    throw "Missing image root: $imageRoot"
}
if (-not (Test-Path -LiteralPath $labelRoot -PathType Container)) {
    throw "Missing label root: $labelRoot"
}

Write-Output "Dataset root: $datasetRoot"
Write-Output "Maximum files per part: $ChunkSize"

$summary = @()

foreach ($split in @('train', 'valid', 'test')) {
    $imageSplit = Join-Path $imageRoot $split
    $labelSplit = Join-Path $labelRoot $split

    $existingImageDirectories = @(Get-ChildItem -LiteralPath $imageSplit -Directory)
    $existingLabelDirectories = @(Get-ChildItem -LiteralPath $labelSplit -Directory)
    if ($existingImageDirectories.Count -gt 0 -or $existingLabelDirectories.Count -gt 0) {
        throw "The $split split already contains subdirectories. No files were moved."
    }

    $images = @(Get-ChildItem -LiteralPath $imageSplit -File | Sort-Object Name)
    $labels = @(Get-ChildItem -LiteralPath $labelSplit -File -Filter '*.txt')

    if ($images.Count -ne $labels.Count) {
        throw "Image/label count mismatch in ${split}: $($images.Count) images and $($labels.Count) labels."
    }

    $labelNames = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($label in $labels) {
        [void]$labelNames.Add($label.BaseName)
    }

    $missingLabels = @($images | Where-Object { -not $labelNames.Contains($_.BaseName) })
    if ($missingLabels.Count -gt 0) {
        throw "Missing labels in $split. First missing label: $($missingLabels[0].BaseName).txt"
    }

    $partCount = [int][Math]::Ceiling($images.Count / [double]$ChunkSize)
    Write-Output "Splitting ${split}: $($images.Count) image/label pairs into $partCount part(s)."

    for ($partNumber = 1; $partNumber -le $partCount; $partNumber++) {
        $partName = 'part_{0:D3}' -f $partNumber
        [void](New-Item -ItemType Directory -Path (Join-Path $imageSplit $partName))
        [void](New-Item -ItemType Directory -Path (Join-Path $labelSplit $partName))
    }

    for ($index = 0; $index -lt $images.Count; $index++) {
        $image = $images[$index]
        $partNumber = [int][Math]::Floor($index / [double]$ChunkSize) + 1
        $partName = 'part_{0:D3}' -f $partNumber

        $sourceImage = $image.FullName
        $sourceLabel = Join-Path $labelSplit ($image.BaseName + '.txt')
        $targetImage = Join-Path (Join-Path $imageSplit $partName) $image.Name
        $targetLabel = Join-Path (Join-Path $labelSplit $partName) ($image.BaseName + '.txt')

        if (Test-Path -LiteralPath $targetImage) {
            throw "Destination image already exists: $targetImage"
        }
        if (Test-Path -LiteralPath $targetLabel) {
            throw "Destination label already exists: $targetLabel"
        }

        [System.IO.File]::Move($sourceImage, $targetImage)
        [System.IO.File]::Move($sourceLabel, $targetLabel)

        if ((($index + 1) % 2500) -eq 0 -or ($index + 1) -eq $images.Count) {
            Write-Output "  ${split}: moved $($index + 1) / $($images.Count) pairs"
        }
    }

    $recursiveImages = @(Get-ChildItem -LiteralPath $imageSplit -File -Recurse)
    $recursiveLabels = @(Get-ChildItem -LiteralPath $labelSplit -File -Filter '*.txt' -Recurse)
    $largestImagePart = (
        Get-ChildItem -LiteralPath $imageSplit -Directory |
        ForEach-Object { (Get-ChildItem -LiteralPath $_.FullName -File).Count } |
        Measure-Object -Maximum
    ).Maximum
    $largestLabelPart = (
        Get-ChildItem -LiteralPath $labelSplit -Directory |
        ForEach-Object { (Get-ChildItem -LiteralPath $_.FullName -File -Filter '*.txt').Count } |
        Measure-Object -Maximum
    ).Maximum

    if ($recursiveImages.Count -ne $images.Count -or $recursiveLabels.Count -ne $labels.Count) {
        throw "Post-move count validation failed for $split."
    }
    if ($largestImagePart -gt $ChunkSize -or $largestLabelPart -gt $ChunkSize) {
        throw "A generated $split part exceeds the chunk size."
    }

    $summary += [pscustomobject]@{
        Split = $split
        Images = $recursiveImages.Count
        Labels = $recursiveLabels.Count
        Parts = $partCount
        LargestImagePart = $largestImagePart
        LargestLabelPart = $largestLabelPart
    }
}

Write-Output ''
Write-Output 'Split completed successfully.'
$summary | Format-Table -AutoSize
