#' Create a data file with all the git commit info of a particular user for some repos
#' 
#' In order to create this data file, all the git repos specified have to be cloned to your
#' local machine (this happens automatically). The result of this function is a data file with
#' information about git commits, and this file can be used as input for `plot_git_commit_time()`
#' (which will visualize the times of day commits were made)
#' 
#' @param username The git name of the peson to track their commits (if you
#'   commit to git under multiple names, you can pass a vector of names)
#' @param repos A list of all the GitHub repos you want to analyze (all these
#'   repos will get cloned locally
#' @param dir The directory where all the git repos will 
#' @param logfile THe name of the data file (the file with all the git lgs
create_git_log_file <- function(
  username = c("Dean Attali", "daattali"),
  repos = c("daattali/beautiful-jekyll",
            "daattali/shinyjs",
            "daattali/timevis",
            "jennybc/bingo"),
  dir ="git_repos_vis",
  logfile = "project-logs.csv") {

  if (!requireNamespace("git2r", quietly = TRUE)) {
    stop("You need to install the 'git2r' package", call. = FALSE)
  }

  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }

  dir <- normalizePath(dir)

  # clone all the git repos into one folder and get their commit messages
  logs <- lapply(repos, function(repo) {
    # get the unique repo
    if (!grepl("/", repo)) {
      stop(repo, " is not a valid repo name (you forgot to specify the user)", call. = FALSE)
    }
    repo_name <- sub(".*/(.*)", replacement = "\\1", repo)
    repo_dir <- file.path(dir, repo_name)

    # clone the repo
    if (dir.exists(repo_dir)) {
      message("Note: Not cloning ", repo, " because a folder with that name already exists")
    } else {
      message("Cloning ", repo)
      repo_url <- paste0("https://github.com/", repo)
      git2r::clone(url = repo_url, local_path = repo_dir,
                   progress = FALSE)
    }

    # get the git log
    repo <- git2r::repository(repo_dir)
    commits <- git2r::commits(repo)

    dates <- unlist(lapply(commits, function(commit) {
      if (commit@author@name %in% username) {
        as.character(as.POSIXlt(commit@author@when@time, origin = "1970-01-01"))
      } else {
        NULL
      }
    }))
    data.frame(project = rep(repo_name, length(dates)),
               timestamp = dates,
               stringsAsFactors = FALSE)
  })

  # write the logs to a file
  logs <- do.call(rbind, logs)
  logfile <- file.path(dir, logfile)
  write.csv(logs, logfile, quote = FALSE, row.names = FALSE)

  if (file.exists(logfile)) {
    message("Created logfile at ", normalizePath(logfile))
  } else {
    stop("The git log file could not get creatd for some reason", call. = FALSE)
  }

  return(logfile)
}