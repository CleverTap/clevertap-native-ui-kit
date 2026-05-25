import 'dart:convert';

import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Enums', () {
    test('ContainerType parses all values', () {
      expect(ContainerType.fromJson('vertical'), ContainerType.vertical);
      expect(ContainerType.fromJson('horizontal'), ContainerType.horizontal);
      expect(ContainerType.fromJson('box'), ContainerType.box);
      expect(ContainerType.fromJson('gallery'), ContainerType.gallery);
      expect(ContainerType.fromJson('unknown'), ContainerType.box); // default
    });

    test('ElementType parses all values', () {
      expect(ElementType.fromJson('text'), ElementType.text);
      expect(ElementType.fromJson('image'), ElementType.image);
      expect(ElementType.fromJson('button'), ElementType.button);
      expect(ElementType.fromJson('video'), ElementType.video);
      expect(ElementType.fromJson('spacer'), ElementType.spacer);
      expect(ElementType.fromJson('divider'), ElementType.divider);
      expect(ElementType.fromJson('html'), ElementType.html);
    });

    test('ArrangementStrategy parses all values', () {
      expect(ArrangementStrategy.fromJson('spaced'), ArrangementStrategy.spaced);
      expect(ArrangementStrategy.fromJson('space_between'), ArrangementStrategy.spaceBetween);
      expect(ArrangementStrategy.fromJson('space_evenly'), ArrangementStrategy.spaceEvenly);
      expect(ArrangementStrategy.fromJson('space_around'), ArrangementStrategy.spaceAround);
      expect(ArrangementStrategy.fromJson('start'), ArrangementStrategy.start);
      expect(ArrangementStrategy.fromJson('center'), ArrangementStrategy.center);
      expect(ArrangementStrategy.fromJson('end'), ArrangementStrategy.end);
    });

    test('AnimationType parses all values', () {
      expect(AnimationType.fromJson('none'), AnimationType.none);
      expect(AnimationType.fromJson('fade_in'), AnimationType.fadeIn);
      expect(AnimationType.fromJson('slide_in_left'), AnimationType.slideInLeft);
      expect(AnimationType.fromJson('slide_in_right'), AnimationType.slideInRight);
      expect(AnimationType.fromJson('slide_in_top'), AnimationType.slideInTop);
      expect(AnimationType.fromJson('slide_in_bottom'), AnimationType.slideInBottom);
      expect(AnimationType.fromJson('scale_in'), AnimationType.scaleIn);
      expect(AnimationType.fromJson('fade_scale_in'), AnimationType.fadeScaleIn);
      expect(AnimationType.fromJson('fade_slide_in'), AnimationType.fadeSlideIn);
    });

    test('TextDimensionUnit parses platform and percent', () {
      expect(TextDimensionUnit.fromJson('platform'), TextDimensionUnit.platform);
      expect(TextDimensionUnit.fromJson('percent'), TextDimensionUnit.percent);
    });

    test('SpecialDimension parses wrap_content and match_parent', () {
      expect(SpecialDimension.fromJson('wrap_content'), SpecialDimension.wrapContent);
      expect(SpecialDimension.fromJson('match_parent'), SpecialDimension.matchParent);
      expect(SpecialDimension.fromJson(null), isNull);
      expect(SpecialDimension.fromJson('unknown'), isNull);
    });
  });

  group('TextDimension', () {
    test('parses raw number as platform unit', () {
      final td = TextDimension.fromJson(14.0);
      expect(td.value, 14.0);
      expect(td.unit, TextDimensionUnit.platform);
    });

    test('parses integer as platform unit', () {
      final td = TextDimension.fromJson(16);
      expect(td.value, 16.0);
      expect(td.unit, TextDimensionUnit.platform);
    });

    test('parses object with unit=percent', () {
      final td = TextDimension.fromJson({'value': 50, 'unit': 'percent'});
      expect(td.value, 50.0);
      expect(td.unit, TextDimensionUnit.percent);
    });

    test('resolves platform unit directly', () {
      final td = TextDimension.fromJson(16.0);
      expect(td.resolve(400), 16.0);
    });

    test('resolves percent as rootHeight * value / 1000', () {
      final td = TextDimension.fromJson({'value': 50, 'unit': 'percent'});
      expect(td.resolve(400), closeTo(20.0, 0.001)); // 400 * 50 / 1000 = 20
    });
  });

  group('Dimension', () {
    test('parses standard object', () {
      final d = Dimension.fromJson({'value': 100, 'unit': 'percent'});
      expect(d.value, 100.0);
      expect(d.unit, DimensionUnit.percent);
      expect(d.special, isNull);
    });

    test('parses wrap_content special', () {
      final d = Dimension.fromJson({'special': 'wrap_content'});
      expect(d.special, SpecialDimension.wrapContent);
    });

    test('fromJsonFlexible parses raw number as dp', () {
      final d = Dimension.fromJsonFlexible(12);
      expect(d.value, 12.0);
      expect(d.unit, DimensionUnit.dp);
    });

    test('fromJsonFlexible parses object', () {
      final d = Dimension.fromJsonFlexible({'value': 50, 'unit': 'percent'});
      expect(d.value, 50.0);
      expect(d.unit, DimensionUnit.percent);
    });
  });

  group('Spacing', () {
    test('resolveTop uses top > vertical > all fallback chain', () {
      expect(Spacing(top: 10, vertical: 20, all: 30).resolveTop(), 10.0);
      expect(Spacing(vertical: 20, all: 30).resolveTop(), 20.0);
      expect(Spacing(all: 30).resolveTop(), 30.0);
      expect(const Spacing().resolveTop(), 0.0);
    });

    test('resolveLeft uses left > horizontal > all fallback chain', () {
      expect(Spacing(left: 5, horizontal: 10, all: 20).resolveLeft(), 5.0);
      expect(Spacing(horizontal: 10, all: 20).resolveLeft(), 10.0);
      expect(Spacing(all: 20).resolveLeft(), 20.0);
      expect(const Spacing().resolveLeft(), 0.0);
    });

    test('parses from JSON', () {
      final s = Spacing.fromJson({'all': 8, 'top': 12});
      expect(s.resolveTop(), 12.0);
      expect(s.resolveBottom(), 8.0);
    });
  });

  group('Style', () {
    test('merge: this takes priority over other', () {
      const s1 = Style(textColor: '#FF0000', fontSize: null);
      const s2 = Style(textColor: '#00FF00', fontSize: TextDimension(value: 14));
      final merged = s1.merge(s2);
      expect(merged.textColor, '#FF0000'); // this wins
      expect(merged.fontSize?.value, 14.0); // falls back to other
    });

    test('merge with null returns this', () {
      const s = Style(textColor: '#FF0000');
      expect(s.merge(null), same(s));
    });

    test('cascadingOnly returns only text properties + opacity', () {
      final s = Style(
        textColor: '#FF0000',
        fontSize: const TextDimension(value: 14),
        background: SolidBackground(color: '#FFFFFF'),
        backgroundColor: '#FFFFFF',
        borderRadius: const Dimension(value: 8),
        shadowColor: '#000000',
        opacity: 0.5,
      );
      final cascading = s.cascadingOnly();
      expect(cascading.textColor, '#FF0000');
      expect(cascading.fontSize?.value, 14.0);
      expect(cascading.opacity, 0.5);
      // Non-cascading properties must be null
      expect(cascading.background, isNull);
      expect(cascading.backgroundColor, isNull);
      expect(cascading.borderRadius, isNull);
      expect(cascading.shadowColor, isNull);
    });

    test('parses from JSON', () {
      final s = Style.fromJson({
        'textColor': '#FFFFFF',
        'fontSize': 16,
        'fontWeight': 'bold',
        'opacity': 0.8,
        'backgroundColor': '#000000',
        'borderRadius': 8,
      });
      expect(s.textColor, '#FFFFFF');
      expect(s.fontSize?.value, 16.0);
      expect(s.fontWeight, NDFontWeight.bold);
      expect(s.opacity, 0.8);
      expect(s.backgroundColor, '#000000');
      expect(s.borderRadius?.value, 8.0);
    });

    test('parses borderRadius as object with unit', () {
      final s = Style.fromJson({'borderRadius': {'value': 50, 'unit': 'percent'}});
      expect(s.borderRadius?.unit, DimensionUnit.percent);
      expect(s.borderRadius?.value, 50.0);
    });
  });

  group('Background', () {
    test('parses solid background', () {
      final b = Background.fromJson({'type': 'solid', 'color': '#FF0000'});
      expect(b, isA<SolidBackground>());
      expect((b as SolidBackground).color, '#FF0000');
    });

    test('parses linear_gradient background', () {
      final b = Background.fromJson({
        'type': 'linear_gradient',
        'angle': 90.0,
        'colors': ['#FF0000', '#0000FF'],
      });
      expect(b, isA<LinearGradientBackground>());
      final lg = b as LinearGradientBackground;
      expect(lg.angle, 90.0);
      expect(lg.colors, ['#FF0000', '#0000FF']);
    });

    test('parses radial_gradient background', () {
      final b = Background.fromJson({
        'type': 'radial_gradient',
        'colors': ['#FFFFFF', '#000000'],
        'center_x': 0.3,
        'center_y': 0.7,
      });
      expect(b, isA<RadialGradientBackground>());
      final rg = b as RadialGradientBackground;
      expect(rg.centerX, 0.3);
      expect(rg.centerY, 0.7);
    });

    test('parses sweep_gradient background', () {
      final b = Background.fromJson({
        'type': 'sweep_gradient',
        'colors': ['#FF0000', '#00FF00', '#0000FF'],
        'start_angle': 45.0,
      });
      expect(b, isA<SweepGradientBackground>());
      expect((b as SweepGradientBackground).startAngle, 45.0);
    });

    test('parses image background', () {
      final b = Background.fromJson({
        'type': 'image',
        'url': 'https://example.com/bg.jpg',
        'fit': 'contain',
      });
      expect(b, isA<ImageBackground>());
      final ib = b as ImageBackground;
      expect(ib.url, 'https://example.com/bg.jpg');
      expect(ib.fit, ImageFit.contain);
    });

    test('parses shimmer background (v2 deferred)', () {
      final b = Background.fromJson({
        'type': 'shimmer',
        'base_color': '#E0E0E0',
        'highlight_color': '#F5F5F5',
      });
      expect(b, isA<ShimmerBackground>());
    });

    test('unknown type returns transparent solid', () {
      final b = Background.fromJson({'type': 'unknown_type'});
      expect(b, isA<SolidBackground>());
      expect((b as SolidBackground).color, '#00000000');
    });
  });

  group('Action', () {
    test('parses open_url action', () {
      final a = NDAction.fromJson({'type': 'open_url', 'url': 'https://clevertap.com'});
      expect(a, isA<OpenUrlAction>());
      expect((a as OpenUrlAction).url, 'https://clevertap.com');
    });

    test('open_url resolves platform-specific url map (ios key)', () {
      final a = NDAction.fromJson({
        'type': 'open_url',
        'url': {'android': 'https://play.google.com', 'ios': 'https://apps.apple.com'},
      });
      expect((a as OpenUrlAction).url, 'https://apps.apple.com');
    });

    test('parses custom action', () {
      final a = NDAction.fromJson({'type': 'custom', 'key': 'add_to_cart', 'value': '123'});
      expect(a, isA<CustomAction>());
      expect((a as CustomAction).key, 'add_to_cart');
    });

    test('parses navigate action', () {
      final a = NDAction.fromJson({'type': 'navigate', 'destination': 'product_detail'});
      expect(a, isA<NavigateAction>());
      expect((a as NavigateAction).destination, 'product_detail');
    });

    test('parses track event action', () {
      final a = NDAction.fromJson({'type': 'event', 'eventName': 'Button Clicked'});
      expect(a, isA<TrackEventAction>());
      expect((a as TrackEventAction).eventName, 'Button Clicked');
    });

    test('parses composite action', () {
      final a = NDAction.fromJson({
        'type': 'composite',
        'executionMode': 'parallel',
        'actions': [
          {'type': 'open_url', 'url': 'https://example.com'},
          {'type': 'event', 'eventName': 'Clicked'},
        ],
      });
      expect(a, isA<CompositeAction>());
      final ca = a as CompositeAction;
      expect(ca.executionMode, ExecutionMode.parallel);
      expect(ca.actions.length, 2);
    });
  });

  group('GalleryConfig', () {
    test('parses defaults', () {
      final g = GalleryConfig.fromJson({});
      expect(g.mode, GalleryMode.snapping);
      expect(g.orientation, Orientation.horizontal);
      expect(g.spacing, 8.0);
    });

    test('parses full config', () {
      final g = GalleryConfig.fromJson({
        'mode': 'free_flow_grid',
        'orientation': 'vertical',
        'snapBehavior': 'start',
        'itemsPerView': 2.5,
        'autoScrollInterval': 3000,
        'infiniteScroll': true,
      });
      expect(g.mode, GalleryMode.freeFlowGrid);
      expect(g.orientation, Orientation.vertical);
      expect(g.snapBehavior, SnapBehavior.start);
      expect(g.itemsPerView, 2.5);
      expect(g.autoScrollInterval, 3000);
      expect(g.infiniteScroll, true);
    });

    test('effectiveItemsPerView uses columns when set', () {
      final g = GalleryConfig.fromJson({'columns': 3, 'itemsPerView': 2.0});
      expect(g.effectiveItemsPerView, 3.0);
    });
  });

  group('NativeDisplayNode', () {
    test('parses container node', () {
      final json = {
        'type': 'container',
        'id': 'root',
        'containerType': 'box',
        'children': [],
        'layout': {
          'width': {'value': 100, 'unit': 'percent'},
          'aspectRatio': 1.777,
        },
      };
      final node = NativeDisplayNode.fromJson(json);
      expect(node, isA<NativeDisplayContainer>());
      final container = node as NativeDisplayContainer;
      expect(container.containerType, ContainerType.box);
      expect(container.layout?.aspectRatio, closeTo(1.777, 0.001));
    });

    test('parses element node', () {
      final json = {
        'type': 'element',
        'id': 'title',
        'elementType': 'text',
        'bindings': {'text': 'Hello World'},
        'layout': {'width': {'value': 100, 'unit': 'percent'}},
      };
      final node = NativeDisplayNode.fromJson(json);
      expect(node, isA<NativeDisplayElement>());
      final element = node as NativeDisplayElement;
      expect(element.elementType, ElementType.text);
      expect(element.bindings['text'], 'Hello World');
    });

    test('parses nested children', () {
      final json = {
        'type': 'container',
        'id': 'outer',
        'containerType': 'box',
        'children': [
          {
            'type': 'element',
            'id': 'inner_text',
            'elementType': 'text',
            'bindings': {'text': 'Nested'},
          },
        ],
      };
      final container = NativeDisplayNode.fromJson(json) as NativeDisplayContainer;
      expect(container.children.length, 1);
      expect(container.children.first, isA<NativeDisplayElement>());
    });

    test('parses actions map', () {
      final json = {
        'type': 'element',
        'id': 'btn',
        'elementType': 'button',
        'bindings': {'text': 'Buy'},
        'actions': {
          'onClick': {'type': 'open_url', 'url': 'https://example.com'},
        },
      };
      final element = NativeDisplayNode.fromJson(json) as NativeDisplayElement;
      expect(element.actions?['onClick'], isA<OpenUrlAction>());
    });

    test('parses imageConfig', () {
      final json = {
        'type': 'element',
        'id': 'img',
        'elementType': 'image',
        'bindings': {'url': 'https://example.com/img.jpg'},
        'imageConfig': {'fit': 'contain', 'animated': true},
      };
      final element = NativeDisplayNode.fromJson(json) as NativeDisplayElement;
      expect(element.imageConfig?.fit, ImageFit.contain);
      expect(element.imageConfig?.animated, true);
    });
  });

  group('NativeDisplayConfig', () {
    test('parses minimal config', () {
      final json = jsonDecode('''
      {
        "root": {
          "type": "element",
          "id": "root_el",
          "elementType": "text",
          "bindings": {"text": "Hello"},
          "layout": {
            "width": {"value": 100, "unit": "percent"},
            "aspectRatio": 2.0
          }
        }
      }
      ''') as Map<String, dynamic>;

      final config = NativeDisplayConfig.fromJson(json);
      expect(config.root, isNotNull);
      expect(config.root, isA<NativeDisplayElement>());
      expect(config.theme, isNull);
      expect(config.styleClasses, isEmpty);
      expect(config.variables, isEmpty);
    });

    test('parses theme and style classes', () {
      final json = {
        'theme': {
          'id': 'dark',
          'defaultStyle': {'textColor': '#FFFFFF', 'backgroundColor': '#000000'},
          'colors': {'primary': '#2196F3'},
        },
        'styleClasses': [
          {
            'name': 'heading',
            'style': {'fontSize': 24, 'fontWeight': 'bold'},
          },
        ],
        'variables': {'title': 'Sale'},
        'root': {
          'type': 'element',
          'id': 'r',
          'elementType': 'text',
          'bindings': {'text': '{{title}}'},
        },
      };
      final config = NativeDisplayConfig.fromJson(json);
      expect(config.theme?.id, 'dark');
      expect(config.theme?.defaultStyle.textColor, '#FFFFFF');
      expect(config.theme?.getColor('primary'), '#2196F3');
      expect(config.styleClasses.length, 1);
      expect(config.styleClasses.first.name, 'heading');
      expect(config.variables['title'], 'Sale');
    });

    test('parses version field', () {
      final json = {
        'version': '2.0',
        'root': {
          'type': 'element',
          'id': 'r',
          'elementType': 'text',
          'bindings': {'text': 'v2'},
        },
      };
      final config = NativeDisplayConfig.fromJson(json);
      expect(config.version, '2.0');
    });
  });

  group('NodeConfig', () {
    test('parses DividerConfig', () {
      final d = DividerConfig.fromJson({
        'orientation': 'vertical',
        'thickness': 2.0,
        'color': '#FF0000',
      });
      expect(d.orientation, Orientation.vertical);
      expect(d.thickness, 2.0);
      expect(d.color, '#FF0000');
    });

    test('DividerConfig uses defaults', () {
      final d = DividerConfig.fromJson({});
      expect(d.orientation, Orientation.horizontal);
      expect(d.thickness, 1.0);
      expect(d.color, '#E0E0E0');
    });

    test('parses HtmlConfig', () {
      final h = HtmlConfig.fromJson({
        'javascriptEnabled': true,
        'scrollEnabled': true,
        'baseUrl': 'https://example.com',
        'transparentBackground': false,
      });
      expect(h.javascriptEnabled, true);
      expect(h.scrollEnabled, true);
      expect(h.baseUrl, 'https://example.com');
      expect(h.transparentBackground, false);
    });

    test('parses NDAnimation', () {
      final a = NDAnimation.fromJson({
        'type': 'fade_in',
        'duration': 500,
        'delay': 100,
        'easing': 'ease_in_out',
      });
      expect(a.type, AnimationType.fadeIn);
      expect(a.duration, 500);
      expect(a.delay, 100);
      expect(a.easing, Easing.easeInOut);
    });
  });
}
