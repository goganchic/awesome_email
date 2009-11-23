# coding: utf-8
$KCODE = 'u' unless RUBY_VERSION >= '1.9'

require 'rubygems'

gem 'nokogiri', '>= 1.3.3'
gem 'css_parser'

require 'nokogiri'
require 'css_parser'


module ActionMailer
  module InlineStyles
    
    STYLE_ATTR = (RUBY_VERSION >= '1.9') ? :style : 'style'
    
    module ClassMethods
      # none
    end
    
    module InstanceMethods
      
      def inline(html)
        css_doc = parse_css_doc(build_css_file_name_from_css_setting)
        html_doc = parse_html_doc(html)
        render_inline(css_doc, html_doc)
      end
      
      def render_message_with_inline_styles(method_name, body)
        message = render_message_without_inline_styles(method_name, body)
        return message if @css.blank? && @less.blank?
        inline(message)
      end
      
      protected
        
        def render_inline(css_doc, html_doc)
          css_doc.each_rule_set do |rule_set|
            inline_css = rule_set.declarations_to_s
            
            rule_set.each_selector do |sel, dec, spec|
              html_doc.css(sel).each do |element|
                element[STYLE_ATTR] = [inline_css, element[STYLE_ATTR]].compact.join('').strip
                element[STYLE_ATTR] << ';' unless element[STYLE_ATTR] =~ /;$/
              end
            end
            
          end
          html_doc.to_html
        end
        
        def parse_html_doc(html)
          html_doc = Nokogiri::HTML.parse(html)
        end
        
        def parse_css_doc(file_name)
          css_doc = CssParser::Parser.new
          css_doc.add_block!(parse_css_from_file(file_name))
          css_doc
        end
        
        def parse_css_from_file(file_name)
          if File.exists?(file_name)
            if File.extname(file_name) == '.less'
              require 'less'
              File.open(file_name) {|f| Less::Engine.new(f) }.to_css
            else
              File.read(file_name)
            end
          else
            ''
          end
        end
        
        def build_css_file_name_from_css_setting
          if @css.blank? && @less.blank?
            return ''
          else
            unless @css.blank?
              build_css_file_name(@css)
            else
              build_less_file_name(@less)
            end
          end
        end
        
        def build_css_file_name(css_name)
          file_name = "#{css_name}.css"
          Dir.glob(File.join(RAILS_ROOT, '**', file_name)).first || File.join(RAILS_ROOT, 'public', 'stylesheets', 'mails', file_name)
        end
        
        def build_less_file_name(less_name)
          file_name = "#{less_name}.less"
          Dir.glob(File.join(RAILS_ROOT, '**', file_name)).first || File.join(RAILS_ROOT, 'stylesheets', 'mails', file_name)
        end
        
    end
    
    def self.included(receiver)
      receiver.class_eval do
        extend ClassMethods
        include InstanceMethods
        
        adv_attr_accessor :css
        adv_attr_accessor :less
        alias_method_chain :render_message, :inline_styles
      end
    end
    
  end
end

ActionMailer::Base.send :include, ActionMailer::InlineStyles
