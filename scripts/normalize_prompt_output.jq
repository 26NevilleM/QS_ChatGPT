# Keep the structure but drop fields that often change
def scrub:
  walk(
    if type == "object" then
      del(.id? | .uuid? | .timestamp? | .generated_at? | .request_id?)
    else .
    end
  );

scrub
