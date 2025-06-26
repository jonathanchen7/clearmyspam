module VerbTenseHelper
  def dispose_verb
    archive? ? "archive" : "delete"
  end

  def disposing_verb
    archive? ? "archiving" : "deleting"
  end

  def disposed_verb
    archive? ? "archived" : "deleted"
  end
end
