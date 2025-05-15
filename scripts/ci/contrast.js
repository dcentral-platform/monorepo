#!/usr/bin/env node
/**
 * WCAG Contrast Checker for Design Tokens
 * 
 * This script validates that all color tokens meet the WCAG 2.1 AA standard
 * for contrast ratio: 4.5:1 for normal text, 3:1 for large text and UI components.
 * 
 * It checks each color against both white and black to ensure it's usable.
 */

const fs = require('fs');
const path = require('path');

// Simple contrast calculation function - returns a value between 1 and 21
function luminance(r, g, b) {
  const a = [r, g, b].map(v => {
    v /= 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  });
  return a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722;
}

function contrast(rgb1, rgb2) {
  const lum1 = luminance(rgb1[0], rgb1[1], rgb1[2]);
  const lum2 = luminance(rgb2[0], rgb2[1], rgb2[2]);
  const brightest = Math.max(lum1, lum2);
  const darkest = Math.min(lum1, lum2);
  return (brightest + 0.05) / (darkest + 0.05);
}

// Parse hex color to RGB
function hexToRgb(hex) {
  // Remove # if present
  hex = hex.replace('#', '');
  
  // Handle shorthand
  if (hex.length === 3) {
    hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
  }
  
  const r = parseInt(hex.substring(0, 2), 16);
  const g = parseInt(hex.substring(2, 4), 16);
  const b = parseInt(hex.substring(4, 6), 16);
  
  return [r, g, b];
}

// Main function
function checkTokens() {
  // Constants
  const WHITE = [255, 255, 255];
  const BLACK = [0, 0, 0];
  const TEXT_CONTRAST_RATIO = 4.5;  // AA level for normal text
  const UI_CONTRAST_RATIO = 3.0;    // AA level for large text and UI components
  
  // Load design tokens
  const tokensPath = path.join(process.cwd(), 'design', 'palette-tokens', 'design-tokens.json');
  
  if (!fs.existsSync(tokensPath)) {
    console.error(`Error: Could not find design tokens at ${tokensPath}`);
    process.exit(1);
  }
  
  let tokens;
  try {
    const tokensContent = fs.readFileSync(tokensPath, 'utf8');
    tokens = JSON.parse(tokensContent);
  } catch (error) {
    console.error(`Error parsing design tokens: ${error.message}`);
    process.exit(1);
  }
  
  // Track issues
  const issues = [];
  const passed = [];
  
  // Process all color tokens
  function processColorCategory(category, colors) {
    for (const [shade, color] of Object.entries(colors)) {
      // Skip if not a hex color
      if (typeof color !== 'string' || !color.startsWith('#')) {
        continue;
      }
      
      const name = `${category}.${shade}`;
      const rgb = hexToRgb(color);
      
      // Check against white background
      const whiteContrast = contrast(rgb, WHITE);
      
      // Check against black background
      const blackContrast = contrast(rgb, BLACK);
      
      // At least one must pass for text
      const textPasses = whiteContrast >= TEXT_CONTRAST_RATIO || blackContrast >= TEXT_CONTRAST_RATIO;
      
      // At least one must pass for UI
      const uiPasses = whiteContrast >= UI_CONTRAST_RATIO || blackContrast >= UI_CONTRAST_RATIO;
      
      if (!textPasses) {
        issues.push({
          name,
          color,
          whiteContrast: whiteContrast.toFixed(2),
          blackContrast: blackContrast.toFixed(2),
          issue: 'Fails AA contrast for normal text (4.5:1)'
        });
      } else if (!uiPasses) {
        issues.push({
          name,
          color,
          whiteContrast: whiteContrast.toFixed(2),
          blackContrast: blackContrast.toFixed(2),
          issue: 'Fails AA contrast for UI components (3:1)'
        });
      } else {
        passed.push({
          name,
          color,
          whiteContrast: whiteContrast.toFixed(2),
          blackContrast: blackContrast.toFixed(2)
        });
      }
    }
  }
  
  // Check each color category
  if (tokens.colors) {
    for (const [category, colors] of Object.entries(tokens.colors)) {
      if (typeof colors === 'object') {
        processColorCategory(category, colors);
      }
    }
  }
  
  // Report results
  console.log(`\n===== WCAG 2.1 AA Contrast Check Results =====`);
  console.log(`Checked ${passed.length + issues.length} color tokens`);
  
  if (issues.length === 0) {
    console.log(`\n✅ All colors pass WCAG 2.1 AA contrast requirements!`);
  } else {
    console.log(`\n❌ Found ${issues.length} colors with contrast issues:`);
    
    issues.forEach(issue => {
      console.log(`\n- ${issue.name} (${issue.color})`);
      console.log(`  White contrast: ${issue.whiteContrast}:1`);
      console.log(`  Black contrast: ${issue.blackContrast}:1`);
      console.log(`  Issue: ${issue.issue}`);
    });
    
    process.exit(1);
  }
  
  // Generate a report file
  const reportPath = path.join(process.cwd(), 'design', 'wcag-report.md');
  let report = `# WCAG 2.1 AA Contrast Check Report\n\n`;
  report += `Generated: ${new Date().toISOString()}\n\n`;
  report += `## Summary\n\n`;
  report += `- Total colors checked: ${passed.length + issues.length}\n`;
  report += `- Colors passing AA requirements: ${passed.length}\n`;
  report += `- Colors with contrast issues: ${issues.length}\n\n`;
  
  if (issues.length > 0) {
    report += `## Issues\n\n`;
    issues.forEach(issue => {
      report += `### ${issue.name} (${issue.color})\n\n`;
      report += `- White contrast: ${issue.whiteContrast}:1\n`;
      report += `- Black contrast: ${issue.blackContrast}:1\n`;
      report += `- Issue: ${issue.issue}\n\n`;
    });
  }
  
  report += `## Passing Colors\n\n`;
  report += `| Token | Color | White Contrast | Black Contrast |\n`;
  report += `|-------|-------|----------------|----------------|\n`;
  
  passed.forEach(item => {
    report += `| ${item.name} | ${item.color} | ${item.whiteContrast}:1 | ${item.blackContrast}:1 |\n`;
  });
  
  fs.writeFileSync(reportPath, report);
  console.log(`\nDetailed report saved to: ${reportPath}`);
}

// Run the check
checkTokens();