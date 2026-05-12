import { definePreset } from '@primeuix/themes';
import Aura from '@primeuix/themes/aura';

/**
 * LCARS — the Library Computer Access/Retrieval System interface from
 * Star Trek: The Next Generation. Pure-black canvas, saturated "panel"
 * colours (amber, African violet, sky/ice blue, salmon), giant pill /
 * "elbow" radii, and the condensed all-caps Antonio typeface.
 *
 * LCARS is intrinsically a *dark* interface: add the `.app-dark` class to
 * <html> (the framework's theme switcher / B1AppConfig does this) so the
 * black surfaces and glowing accents render as intended.
 */
const LcarsPreset = definePreset(Aura, {
  // 1. Custom design tokens — camelCase => dot path (e.g. my.bar.height)
  extend: {
    my: {
      barHeight: '2.25rem',
      panelRadius: '1.75rem',
      pillRadius: '999px',
      lcarsGap: '0.3125rem' // the black seam between LCARS panels
    }
  },

  // 2. Global CSS — keep it small; LCARS is mostly colour + radius + caps
  css: ({ dt }: any) => `
    /* Always-black canvas, the way the Enterprise computer likes it */
    .app-dark body,
    .app-dark #__nuxt {
      background: #000000;
    }

    /* Condensed, upper-case "panel labels" */
    .p-button,
    .p-menubar .p-menubar-item-label,
    .p-menu .p-menu-item-label,
    .p-tabs .p-tab,
    .p-panel .p-panel-title,
    .p-card .p-card-title,
    .p-datatable .p-datatable-column-title,
    h1, h2, h3 {
      text-transform: uppercase;
      letter-spacing: 0.06em;
      font-weight: 600;
    }

    /* LCARS panels carry a colour bar on the header */
    .p-panel .p-panel-header {
      border-top-left-radius: ${dt('my.panel.radius')};
      border-top-right-radius: ${dt('my.panel.radius')};
    }

    /* Chunky, glowing accent scrollbars */
    .app-dark ::-webkit-scrollbar { width: 12px; height: 12px; }
    .app-dark ::-webkit-scrollbar-track { background: #000; }
    .app-dark ::-webkit-scrollbar-thumb {
      background: ${dt('primary.color')};
      border-radius: ${dt('my.pill.radius')};
    }
  `,

  // 3. Primitive colour ramps — the canonical LCARS palette, 50 → 950
  primitive: {
    // Signature LCARS amber/orange ("Neon Carrot")
    lcarsOrange: {
      50: '#fff5e6',
      100: '#ffe6bf',
      200: '#ffd699',
      300: '#ffc266',
      400: '#ffad33',
      500: '#ff9900',
      600: '#e88a00',
      700: '#cc7700',
      800: '#a35f00',
      900: '#7a4700',
      950: '#4d2c00'
    },
    // "African Violet" / mauve
    lcarsViolet: {
      50: '#f8f1f8',
      100: '#efe1ef',
      200: '#e1c7e1',
      300: '#d2add2',
      400: '#cc99cc',
      500: '#bb7fbb',
      600: '#a366a3',
      700: '#854d85',
      800: '#663866',
      900: '#4d294d',
      950: '#331a33'
    },
    // Sky / "Anakiwa" ice blue
    lcarsIce: {
      50: '#eef5ff',
      100: '#d9e8ff',
      200: '#b3d1ff',
      300: '#8cb9ff',
      400: '#669ee6',
      500: '#5588cc',
      600: '#4675b3',
      700: '#3a5f8f',
      800: '#2c486b',
      900: '#1f3349',
      950: '#121d2b'
    },
    // Salmon / "Red Damask" — warnings & destructive actions
    lcarsSalmon: {
      50: '#fdf0ef',
      100: '#fadcdb',
      200: '#f2b8b6',
      300: '#e89593',
      400: '#dd7c79',
      500: '#cc6666',
      600: '#b95252',
      700: '#9c4242',
      800: '#7d3636',
      900: '#5e2b2b',
      950: '#3d1c1c'
    },
    // Near-black "space" surface ramp (0 lightest → 950 black)
    space: {
      0: '#ffffff',
      50: '#f7f7f8',
      100: '#ededee',
      200: '#d4d4d6',
      300: '#a8a8ac',
      400: '#7a7a7e',
      500: '#545458',
      600: '#3d3d40',
      700: '#2b2b2e',
      800: '#1a1a1c',
      900: '#0c0c0d',
      950: '#000000'
    }
  },

  // 4. Semantic mapping — primary = LCARS amber; surfaces = "space"
  semantic: {
    primary: {
      50: '{lcarsOrange.50}',
      100: '{lcarsOrange.100}',
      200: '{lcarsOrange.200}',
      300: '{lcarsOrange.300}',
      400: '{lcarsOrange.400}',
      500: '{lcarsOrange.500}',
      600: '{lcarsOrange.600}',
      700: '{lcarsOrange.700}',
      800: '{lcarsOrange.800}',
      900: '{lcarsOrange.900}',
      950: '{lcarsOrange.950}'
    },
    // condensed LCARS typeface (Antonio is loaded in nuxt.config.ts)
    fontFamily: "'Antonio', 'Plus Jakarta Sans', ui-sans-serif, system-ui, sans-serif", // eslint-disable-line
    // big pill-shaped form fields
    formField: {
      borderRadius: '{border.radius.lg}'
    },
    // crank up the radius primitives so everything reads as an LCARS "elbow"
    borderRadius: {
      none: '0',
      xs: '4px',
      sm: '12px',
      md: '18px',
      lg: '24px',
      xl: '36px'
    },
    colorScheme: {
      light: {
        // black text on amber chips/buttons
        primary: {
          color: '{lcarsOrange.500}',
          contrastColor: '#000000',
          hoverColor: '{lcarsOrange.400}',
          activeColor: '{lcarsOrange.600}'
        }
      },
      dark: {
        primary: {
          color: '{lcarsOrange.500}',
          contrastColor: '#000000',
          hoverColor: '{lcarsOrange.400}',
          activeColor: '{lcarsOrange.600}'
        },
        // black canvas, faintly-lit panels
        surface: {
          0: '#ffffff',
          50: '{space.50}',
          100: '{space.100}',
          200: '{space.200}',
          300: '{space.300}',
          400: '{space.400}',
          500: '{space.500}',
          600: '{space.600}',
          700: '{space.700}',
          800: '{space.800}',
          900: '{space.900}',
          950: '{space.950}'
        }
      }
    }
  },

  // 5. Component overrides — pill buttons, colour-bar panel headers, etc.
  components: {
    button: {
      root: {
        borderRadius: '{my.pill.radius}',
        roundedBorderRadius: '{my.pill.radius}',
        paddingX: '1.25rem',
        gap: '0.5rem',
        label: { fontWeight: '600' },
        sm: { paddingX: '0.875rem' },
        lg: { paddingX: '1.625rem' }
      },
      colorScheme: {
        dark: {
          // secondary / info / danger buttons take the rest of the LCARS palette
          secondary: {
            background: '{lcarsViolet.400}',
            hoverBackground: '{lcarsViolet.300}',
            activeBackground: '{lcarsViolet.500}',
            borderColor: 'transparent',
            hoverBorderColor: 'transparent',
            activeBorderColor: 'transparent',
            color: '#000000',
            hoverColor: '#000000',
            activeColor: '#000000'
          },
          info: {
            background: '{lcarsIce.300}',
            hoverBackground: '{lcarsIce.200}',
            activeBackground: '{lcarsIce.400}',
            borderColor: 'transparent',
            hoverBorderColor: 'transparent',
            activeBorderColor: 'transparent',
            color: '#000000',
            hoverColor: '#000000',
            activeColor: '#000000'
          },
          danger: {
            background: '{lcarsSalmon.500}',
            hoverBackground: '{lcarsSalmon.400}',
            activeBackground: '{lcarsSalmon.600}',
            borderColor: 'transparent',
            hoverBorderColor: 'transparent',
            activeBorderColor: 'transparent',
            color: '#000000',
            hoverColor: '#000000',
            activeColor: '#000000'
          }
        }
      }
    },
    card: {
      root: {
        borderRadius: '{my.panel.radius}'
      },
      title: { fontWeight: '600' }
    },
    panel: {
      root: { borderRadius: '{my.panel.radius}' },
      header: {
        background: '{primary.color}',
        color: '{primary.contrastColor}',
        padding: '0.625rem 1.25rem'
      },
      title: { fontWeight: '700' }
    },
    fieldset: {
      root: { borderRadius: '{my.panel.radius}' },
      legend: {
        background: '{primary.color}',
        color: '{primary.contrastColor}',
        borderRadius: '{my.pill.radius}'
      }
    },
    datatable: {
      // header row reads as a violet LCARS "label strip"
      headerCell: {
        colorScheme: {
          dark: {
            background: '{lcarsViolet.400}',
            color: '#000000',
            hoverBackground: '{lcarsViolet.300}',
            hoverColor: '#000000'
          }
        }
      },
      row: { background: 'transparent' }
    },
    tabs: {
      tablist: { background: 'transparent' },
      tabpanel: { background: 'transparent' },
      tab: { fontWeight: '600' },
      activeBar: { background: '{primary.color}' }
    },
    tag: {
      root: { borderRadius: '{my.pill.radius}', fontWeight: '700' }
    },
    badge: {
      root: { borderRadius: '{my.pill.radius}', fontWeight: '700' }
    },
    chip: {
      root: { borderRadius: '{my.pill.radius}' }
    },
    message: {
      root: { borderRadius: '{my.panel.radius}' }
    },
    toast: {
      root: { borderRadius: '{my.panel.radius}' }
    },
    progressbar: {
      value: { background: '{primary.color}' }
    },
    slider: {
      range: { background: '{primary.color}' },
      handle: {
        colorScheme: {
          dark: { background: '{primary.color}', contentBackground: '{primary.color}' }
        }
      }
    },
    toggleswitch: {
      colorScheme: {
        dark: {
          root: { checkedBackground: '{primary.color}', checkedHoverBackground: '{primary.hover.color}' }
        }
      }
    }
  }
});

export default {
  preset: LcarsPreset,
  options: {
    prefix: 'p',
    darkModeSelector: '.app-dark',
    cssLayer: {
      name: 'primevue',
      order: 'theme, base, primevue'
    }
  }
};
