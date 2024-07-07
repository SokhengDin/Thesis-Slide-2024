# Install and load required packages
if (!require(officer)) install.packages("officer")
if (!require(rvest)) install.packages("rvest")
if (!require(magrittr)) install.packages("magrittr")
library(officer)
library(rvest)
library(magrittr)

# Function to read and parse R Markdown file
parse_rmd <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)
  slides <- list()
  current_slide <- character()
  in_yaml <- FALSE
  
  for (line in lines) {
    if (startsWith(line, "---")) {
      in_yaml <- !in_yaml
      if (!in_yaml && length(current_slide) > 0) {
        slides[[length(slides) + 1]] <- current_slide
        current_slide <- character()
      }
    } else if (!in_yaml) {
      current_slide <- c(current_slide, line)
    }
  }
  
  if (length(current_slide) > 0) {
    slides[[length(slides) + 1]] <- current_slide
  }
  
  return(slides)
}

# Function to create PowerPoint slide
create_slide <- function(ppt, slide_content) {
  slide <- add_slide(ppt)
  
  # Extract title (assume first non-empty line starting with # is title)
  title_index <- which(grepl("^#", slide_content) & nzchar(slide_content))[1]
  if (!is.na(title_index)) {
    title <- gsub("^#+ *", "", slide_content[title_index])
    slide <- ph_with_text(slide, type = "title", str = title)
    slide_content <- slide_content[-title_index]
  }
  
  # Process content
  for (i in seq_along(slide_content)) {
    line <- slide_content[i]
    
    # Handle images
    if (grepl("^\\s*!\\[.*\\]\\(.*\\)", line)) {
      img_path <- gsub("^.*\\((.*)\\).*$", "\\1", line)
      slide <- ph_with_img(slide, src = img_path, type = "body")
    }
    # Handle bullet points
    else if (grepl("^\\s*[\\+\\-\\*]", line)) {
      text <- gsub("^\\s*[\\+\\-\\*]\\s*", "", line)
      slide <- ph_add_text(slide, str = text, type = "body", level = 1)
    }
    # Handle normal text
    else if (nzchar(trimws(line))) {
      slide <- ph_add_text(slide, str = line, type = "body")
    }
  }
  
  return(slide)
}

# Main conversion function
rmd_to_pptx <- function(rmd_file, pptx_file) {
  slides <- parse_rmd(rmd_file)
  
  # Create PowerPoint presentation
  ppt <- read_pptx()
  
  # Process each slide
  for (slide_content in slides) {
    ppt <- create_slide(ppt, slide_content)
  }
  
  # Save PowerPoint file
  print(ppt, target = pptx_file)
}

# Usage
rmd_to_pptx("thesis-bachelor-2024.Rmd", "thesis-bachelor-2024.pptx")

cat("PowerPoint file has been created: thesis-bachelor-2024.pptx\n")

