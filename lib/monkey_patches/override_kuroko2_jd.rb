module Kuroko2
  module PrependedMethods
    # MEMO:
    # selfをsaveしてもhas_manyの関係にあるrevisionsが一緒に保存されない不具合がある。
    # 原因は不明で解決できなかった。だが、selfを最初に保存してから後から関連するrevisions
    # を作成して保存するというやり方だと保存できたのでモンキーパッチを当てて解決した。
    # 修正前後で挙動は変わらないので安全なモンキーパッチであるはずである。
    # こちらのIssueに関連している。
    # https://github.com/cookpad/kuroko2/issues/125#issue-378985754
    def save_and_record_revision(edited_user: nil)
      save
      record_revision(edited_user: edited_user)
      revisions.each(&:save)
    end
  end
end

Kuroko2::JobDefinition.prepend Kuroko2::PrependedMethods

