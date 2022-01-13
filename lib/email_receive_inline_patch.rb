#encoding: utf-8

module MailHandlerRemoveInlineImagesPatch
  def add_attachments(obj)
    truncated = decoded_html.split(INVISIBLE_EMAIL_HEADER_DECODED, 2)[1]
    if truncated
      truncated.scan(FIND_IMG_SRC_PATTERN) do |_, src, _|
        src.match(/^cid:(.+)/) do |m|
          remove_part_with_cid(email.parts, m[1])
        end
      end
    end
    add_attachments_without_remove_inline_images obj
  end

  def decoded_html
    return @decoded_html unless @decoded_html.nil?
    @decoded_html = decode_part_body(email.html_part)
  end

  private

  def remove_part_with_cid(parts, cid_to_remove)
    parts.select! do |part|
      keep = part.cid != cid_to_remove
      remove_part_with_cid(part.parts, cid_to_remove) if keep
      keep
    end
  end

  def decode_part_body(p)
    body_charset = Mail::RubyVer.respond_to?(:pick_encoding) ?
        Mail::RubyVer.pick_encoding(email.html_part.charset).to_s : p.charset
    Redmine::CodesetUtil.to_utf8(p.body.decoded, body_charset)
  end
end

MailHandler.send(:include, MailHandlerRemoveInlineImagesPatch)

