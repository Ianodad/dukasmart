import "./index.css";
import { Composition } from "remotion";
import { DukaPromo, PROMO_DURATION_FRAMES } from "./DukaPromo";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="DukaPromo"
      component={DukaPromo}
      durationInFrames={PROMO_DURATION_FRAMES}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
