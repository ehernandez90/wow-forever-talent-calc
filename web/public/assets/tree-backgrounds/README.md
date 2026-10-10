# Generated class talent-tree backgrounds

Place the nine generated class panorama assets in this folder using these exact names:

- druid.webp
- hunter.webp
- mage.webp
- paladin.webp
- priest.webp
- rogue.webp
- shaman.webp
- warlock.webp
- warrior.webp

Each 2:1 panorama contains the class's three talent-tree themes from left to right. `TreePanel.tsx` selects the left, center, or right third based on the tree's `order` field. Assets are intentionally kept in `public/` so Vite copies them unchanged and GitHub Pages can serve them under `BASE_URL`.
