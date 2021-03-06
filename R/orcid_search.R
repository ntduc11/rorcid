#' Orcid search - more user friendly than [orcid()]
#'
#' @export
#' @param given_name (character) given name
#' @param family_name (character) family name
#' @param past_inst (character) past institution
#' @param current_inst (character) current institution
#' @param affiliation_org (character) affiliation organization name
#' @param ringgold_org_id (character) ringgold organization id
#' @param grid_org_id (character) grid organization id
#' @param credit_name (character) credit name
#' @param other_name (character) other name
#' @param email (character) email
#' @param digital_object_ids (character) digital object ids
#' @param work_title (character) work title
#' @param grant_number (character) grant number
#' @param keywords (character) keywords to search. character vector, one
#' or more keywords
#' @param text (character) text to search
#' @param rows (integer) number of records to return
#' @param start (integer) record number to start at
#' @param ... curl options passed on to [crul::HttpClient]
#' @seealso [orcid()]
#' @references <https://members.orcid.org/api/tutorial/search-orcid-registry>
#' @return a `data.frame` with three columns:
#'
#' - first: given name
#' - last: family name
#' - orcid: ORCID identifier
#'
#' If no results are found, an empty (0 rows) data.frame
#' is returned
#' 
#' @note `current_prim_inst` and `patent_number` parameters have been
#' removed as ORCID has removed them
#'
#' @details The goal of this function is to make a human friendly
#' way to search ORCID.
#'
#' Thus, internally we map the parameters given to this function
#' to the actual parameters that ORCID wants that are not
#' so human friendly.
#'
#' We don't include all possible fields you could search against
#' here - for that use [orcid()]
#' 
#' Importantly, we return the first 10 results, following the default 
#' setting for the `rows` parameter in [orcid()]. You can set the rows
#' parameter in this function to a max of 200. The maximum is an 
#' upper bound set by the ORCID API. You can get the number of results
#' found programatically by fetching the `found` attribute on the ouput
#' of this function, e.g., `attr(x, "found")`.
#'
#' @section How parameters are combined:
#' We combine multiple parameters with `AND`, such that
#' e.g., `given_name="Jane"` and `family_name="Doe"` gets passed
#' to ORCID as `given-names:Jane AND family-name:Doe`
#'
#' @examples \dontrun{
#' orcid_search(given_name = "carl", family_name = "boettiger")
#' orcid_search(given_name = "carl")
#' orcid_search(given_name = "carl", rows = 2)
#' orcid_search(keywords = c("birds", "turtles"))
#' orcid_search(affiliation_org = '("Boston University" OR BU)')
#' orcid_search(ringgold_org_id = '1438')
#' orcid_search(grid_org_id = 'grid.5509.9')
#' orcid_search(current_inst = '')
#' orcid_search(email = '*@orcid.org')
#' orcid_search(given_name = "carl", verbose = TRUE)
#' # get number of results found
#' x <- orcid_search(ringgold_org_id = '1438')
#' attr(x, "found")
#' }
orcid_search <- function(given_name = NULL, family_name = NULL,
    past_inst = NULL, current_inst = NULL,
    affiliation_org = NULL, ringgold_org_id = NULL, grid_org_id = NULL,
    credit_name = NULL, other_name = NULL,
    email = NULL, digital_object_ids = NULL, work_title = NULL,
    grant_number = NULL, keywords = NULL,
    text = NULL, rows = 10, start = NULL, ...) {

  query <- ocom(list(given_name = given_name, family_name = family_name,
    past_inst = past_inst,
    current_inst = current_inst, affiliation_org = affiliation_org,
    ringgold_org_id = ringgold_org_id, grid_org_id = grid_org_id,
    credit_name = credit_name, other_name = other_name, email = email,
    digital_object_ids = digital_object_ids, work_title = work_title,
    grant_number = grant_number,
    text = text))
  if (length(query) == 0 && is.null(keywords))
    stop("must pass at least one param")
  names(query) <- vapply(names(query), function(z) field_match_list[[z]], "")
  if (!is.null(keywords)) {
    query <- c(query,
      as.list(stats::setNames(keywords, rep("keyword", length(keywords))))
    )
  }

  # by default, combine with 'AND'
  query <- paste(names(query), unname(query), sep = ":", collapse = " AND ")

  tt <- orcid(query = query, rows = rows, start = start, ...)
  if (!"orcid-identifier.path" %in% names(tt)) return(tibble::tibble())
  as_dt(lapply(tt$`orcid-identifier.path`, function(w) {
    rr <- orcid_id(w)
    data.frame(
      first = rr[[1]]$name$`given-names`$value %||% NA_character_,
      last = rr[[1]]$name$`family-name`$value %||% NA_character_,
      orcid = w,
      stringsAsFactors = FALSE
    )
  }), att = list(found = attr(tt, "found")))
}

field_match_list <- list(
  orcid = 'orcid',
  given_name = 'given-names',
  family_name = 'family-name',
  past_inst = 'past-institution-affiliation-name',
  current_inst = 'current-institution-affiliation-name',
  affiliation_org = 'affiliation-org-name',
  ringgold_org_id = 'ringgold-org-id',
  grid_org_id = 'grid-org-id',
  credit_name = 'credit-name',
  other_name = 'other-names',
  email = 'email',
  digital_object_ids = 'digital-object-ids',
  work_title = 'work-titles',
  grant_number = 'grant-numbers',
  text = 'text'
)
