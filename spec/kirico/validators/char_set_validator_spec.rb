# frozen_string_literal: true
require 'spec_helper'

describe Kirico::CharsetValidator do
  describe '#retrieve_error_chars' do
    let(:validator) { Kirico::CharsetValidator.new(attributes: :hoge) }
    subject { validator.retrieve_error_chars(str) }
    context 'when str contains valid chars' do
      let(:str) { 'あいうえお' }
      it { is_expected.to be_empty }
    end
    context 'when str contains INVALID char(s) - 1' do
      let(:str) { 'あ ｨ い ｩ う ｧ え' }
      it { is_expected.to eq %w(ｨ ｩ ｧ) }
    end
    context 'when str contains INVALID char(s) - 2' do
      let(:str) {
        <<-TEXT
          氏名: 髙﨑裕太
          生年月日: ㍼59年06月09日
          社員№: 69
          役職: ㊤級役員
          住所: ロクロタワーⅢ'
          ℡: 080-696-6969
          身長: 169.6㎝
          体重: 69.6㎏
        TEXT
      }
      it { is_expected.to match_array %w(髙 﨑 № ㊤ Ⅲ ℡ ㍼ ㎝ ㎏) }
    end
  end

  describe '#validate_each' do
    class CharsetValidatable
      include ActiveModel::Validations
      validates_with Kirico::CharsetValidator, attributes: :my_charset_field
      attr_accessor :my_charset_field
    end

    subject { CharsetValidatable.new }
    before { allow(subject).to receive(:my_charset_field) { my_field } }

    context 'empty' do
      let(:my_field) { nil }
      it { expect(subject).to be_valid }
    end

    context '半角記号' do
      %w(
        ! " # $ % & ' ( ) * + , - . /
        : ; < = > ? @
        [ \ ] ^ _ `
        { | } ~
      ).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is allowed" do
          expect(subject).to be_valid
        end
      end
    end

    describe '半角スペース' do
      let(:my_field) { ' ' }
      it { is_expected.to be_valid }
    end

    describe 'タブ文字' do
      let(:my_field) { "\t" }
      it { is_expected.not_to be_valid }
    end

    context '半角英数字' do
      %w(
        0 1 2 3 4 5 6 7 8 9 0
        A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
        a b c d e f g h i j k l m n o p q r s t u v w x y z
      ).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is allowed" do
          expect(subject).to be_valid
        end
      end
    end

    context '全角記号' do
      %w(
        　 、 。 ， ． ・ ： ； ？ ！ ゛ ゜ ´ ｀ ¨
        ＾ ￣ ＿ ヽ ヾ ゝ ゞ 〃 仝 々 〆 〇 ー ― ‐ ／
        ＼ ～ ∥ ｜ … ‥ ‘ ’ “ ” （ ） 〔 〕 ［ ］
        ｛ ｝ 〈 〉 《 》 「 」 『 』 【 】 ＋ － ± ×
        ÷ ＝ ≠ ＜ ＞ ≦ ≧ ∞ ∴ ♂ ♀ ° ′ ″ ℃ ￥
        ＄ ￠ ￡ ％ ＃ ＆ ＊ ＠ § ☆ ★ ○ ● ◎ ◇
        □ ■ △ ▲ ▽ ▼ ※ 〒 → ← ↑ ↓ 〓
      ).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is allowed" do
          expect(subject).to be_valid
        end
      end
    end

    context '全角ひらがな' do
      %w(
        ぁ あ ぃ い ぅ う ぇ え ぉ お
        か が き ぎ く ぐ け げ こ ご
        さ ざ し じ す ず せ ぜ そ ぞ
        た だ ち ぢ っ つ づ て で と ど
        な に ぬ ね の
        は ば ぱ ひ び ぴ ふ ぶ ぷ へ べ ぺ ほ ぼ ぽ
        ま み む め も
        ゃ や ゅ ゆ ょ よ
        ら り る れ ろ
        ゎ わ ゐ ゑ を ん
      ).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is allowed" do
          expect(subject).to be_valid
        end
      end
    end

    context '（JISX0208 未定義）全角ひらがな' do
      %w(ゔ ゕ ゖ ゙ ゚ ゛ ゜ ゝ ゞ ゟ).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '全角カタカナ' do
      %w(
        ァ ア ィ イ ゥ ウ ェ エ ォ オ
        カ ガ キ ギ ク グ ケ ゲ コ ゴ
        サ ザ シ ジ ス ズ セ ゼ ソ ゾ
        タ ダ チ ヂ ッ ツ ヅ テ デ ト ド
        ナ ニ ヌ ネ ノ
        ハ バ パ ヒ ビ ピ フ ブ プ ヘ ベ ペ ホ ボ ポ
        マ ミ ム メ モ
        ャ ヤ ュ ユ ョ ヨ
        ラ リ ル レ ロ
        ヮ ワ ヰ ヱ ヲ ン
        ヴ ヵ ヶ
      ).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is allowed" do
          expect(subject).to be_valid
        end
      end
    end

    context '（JISX0208 未定義）全角カタカナ' do
      %w(ヷ ヸ ヹ ヺ).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '常用漢字（JIS 第 1 & 2 水準漢字）' do
      %w(内 藤 研 介 高 崎).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is allowed" do
          expect(subject).to be_valid
        end
      end
    end

    context '常用外漢字（JIS 第 1 & 2 水準漢字以外）' do
      %w(髙 﨑 亝).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '囲み英数字（丸文字）' do
      %w(① ② ③ ④ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩ ⑪ ⑫ ⑬ ⑭ ⑮ ⑯ ⑰ ⑱ ⑲ ⑳).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context 'ローマ数字' do
      %w(Ⅰ Ⅱ Ⅲ Ⅳ Ⅴ Ⅵ Ⅶ Ⅷ Ⅸ Ⅹ).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '単位記号' do
      %w(㍉ ㌔ ㌢ ㍍ ㌘ ㌧ ㌃ ㌶ ㍑ ㍗ ㌍ ㌦ ㌣ ㌫ ㍊ ㌻ ㎜ ㎝ ㎞ ㎎ ㎏ ㏄ ㎡).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '年号' do
      %w(㍾ ㍽ ㍼ ㍻).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '囲み文字' do
      %w(㊤ ㊥ ㊦ ㊧ ㊨ ㈱ ㈲ ㈹).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '省略文字' do
      %w(№ ㏍ ℡).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '数学記号' do
      %w(≒ ≡ ∫ ∮ Σ √ ⊥ ∠ ∟ ⊿ ∵ ∩ ∪).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '半角カタカナ等' do
      %w(
        ｡ ｢ ｣ ､ ･
        ｦ ｧ ｨ ｩ ｪ ｫ ｬ ｭ ｮ ｯ ｰ
        ｱ ｲ ｳ ｴ ｵ ｶ ｷ ｸ ｹ ｺ ｻ ｼ ｽ ｾ ｿ
        ﾀ ﾁ ﾂ ﾃ ﾄ ﾅ ﾆ ﾇ ﾈ ﾉ ﾊ ﾋ ﾌ ﾍ ﾎ
        ﾏ ﾐ ﾑ ﾒ ﾓ ﾔ ﾕ ﾖ ﾗ ﾘ ﾙ ﾚ ﾛ ﾜ ﾝ
        ﾞ ﾟ
      ).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context 'その他' do
      %w(〝 〟 〄).each do |ch|
        let(:my_field) { ch }
        it "#{ch} is NOT allowed" do
          expect(subject).not_to be_valid
        end
      end
    end

    context '全角チルダ（U+FF5E）と波ダッシュ（U+301C）' do
      describe '全角チルダ（U+FF5E） is NOT allowed' do
        let(:my_field) { '～' }
        it { expect(subject).to be_valid }
      end
      describe '波ダッシュ（U+301C） is allowed' do
        let(:my_field) { '〜' }
        it { expect(subject).not_to be_valid }
      end
    end
  end
end
