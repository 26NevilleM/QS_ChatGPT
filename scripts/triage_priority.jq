. as $o
| ( ($o.summary // "" | ascii_downcase) ) as $s
| if   ($s|test("\\b(invoice|billing|payment|refund)\\b")) then .category = "billing"
  elif ($s|test("\\b(bug|error|crash|exception|stack)\\b")) then .category = "bug"
  elif ($s|test("\\b(feature|request|idea|improvement)\\b")) then .category = "feature_request"
  else .
  end
