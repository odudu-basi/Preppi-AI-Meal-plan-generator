#!/usr/bin/env python3
"""
Script to remove background from mascot image
Requires: pip install pillow rembg
"""

from rembg import remove
from PIL import Image
import os

# Input and output paths
input_path = "/Users/oduduabasivictor/Downloads/ChatGPT Image Oct 23, 2025 at 06_54_56 PM.png"
output_path = "/Users/oduduabasivictor/Desktop/Preppi AI/Preppi AI/Assets.xcassets/PreppiMascot.imageset/PreppiMascot_Transparent.png"

try:
    # Open the input image
    print(f"Opening image: {input_path}")
    input_image = Image.open(input_path)

    # Remove the background
    print("Removing background...")
    output_image = remove(input_image)

    # Save the output image
    print(f"Saving transparent image to: {output_path}")
    output_image.save(output_path)

    print("Success! Background removed.")
    print(f"Transparent image saved to: {output_path}")

except Exception as e:
    print(f"Error: {e}")
    print("\nMake sure you have installed the required packages:")
    print("  pip install pillow rembg")
